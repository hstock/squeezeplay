/*
** Copyright 2007-2008 Logitech. All Rights Reserved.
**
** This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.
*/

#define RUNTIME_DEBUG 1

#include "common.h"

#include "portaudio.h"

#include "audio/fifo.h"
#include "audio/mqueue.h"
#include "audio/decode/decode.h"
#include "audio/decode/decode_priv.h"


/* Portaudio stream */
static PaStreamParameters outputParam;
static PaStream *stream;

/* Stream sample rate */
static bool_t change_sample_rate;
static u32_t stream_sample_rate;


static void decode_portaudio_openstream(void);


/*
 * This function is called by portaudio when the stream is active to request
 * audio samples
 */
static int callback(const void *inputBuffer,
		    void *outputBuffer,
		    unsigned long framesPerBuffer,
		    const PaStreamCallbackTimeInfo *timeInfo,
		    PaStreamCallbackFlags statusFlags,
		    void *userData) {
	size_t bytes_used, len;
	bool_t reached_start_point;
	Uint8 *outputArray;

	if (statusFlags & (paOutputUnderflow | paOutputOverflow)) {
		DEBUG_TRACE("pa status %x\n", (unsigned int)statusFlags);
	}

	// XXXX full port from ip3k

	len = SAMPLES_TO_BYTES(framesPerBuffer);

	/* audio running? */
	if (!(current_audio_state & DECODE_STATE_RUNNING)) {
		memset(outputBuffer, 0, len);
		return 0;
	}

	fifo_lock(&decode_fifo);

	bytes_used = fifo_bytes_used(&decode_fifo);	
	if (bytes_used > len) {
		bytes_used = len;
	}

	/* audio underrun? */
	if (bytes_used == 0) {
		current_audio_state |= DECODE_STATE_UNDERRUN;
		memset(outputBuffer, 0, len);

		fifo_unlock(&decode_fifo);
		return 0;
	}

	if (bytes_used < len) {
		current_audio_state |= DECODE_STATE_UNDERRUN;
		memset(outputBuffer + bytes_used, 0, len - bytes_used);
	}
	else {
		current_audio_state &= ~DECODE_STATE_UNDERRUN;
	}

	outputArray = (u8_t *)outputBuffer;
	while (bytes_used) {
		size_t wrap, bytes_write;

		wrap = fifo_bytes_until_rptr_wrap(&decode_fifo);

		bytes_write = bytes_used;
		if (wrap < bytes_write) {
			bytes_write = wrap;
		}

		memcpy(outputArray, decode_fifo_buf + decode_fifo.rptr, bytes_write);
		fifo_rptr_incby(&decode_fifo, bytes_write);
		decode_elapsed_samples += BYTES_TO_SAMPLES(bytes_write);

		outputArray += bytes_write;
		bytes_used -= bytes_write;
	}

	reached_start_point = decode_check_start_point();
	if (reached_start_point && current_sample_rate != stream_sample_rate) {
		change_sample_rate = true;

		fifo_unlock(&decode_fifo);
		return paComplete;
	}

	fifo_unlock(&decode_fifo);
	return paContinue;
}


static void finished_handler(void) {
	PaError err;

	mqueue_read_complete(&decode_mqueue);
	decode_portaudio_openstream();

	if ((err = Pa_StartStream(stream)) != paNoError) {
		DEBUG_ERROR("PA error %s", Pa_GetErrorText(err));
		return;
	}
}


/*
 * This function is called when the stream needs to be reopened at a
 * different sample rate.
 */
static void finished(void *userData) {
	if (change_sample_rate) {
		/* We can't change the sample rate in this thread, so queue a request for
		 * the decoder thread to service
		 */
		if (mqueue_write_request(&decode_mqueue, finished_handler, 0)) {
			mqueue_write_complete(&decode_mqueue);
		}
		else {
			DEBUG_TRACE("Full message queue, dropped finished message");
		}
	}
}


static void decode_portaudio_start(void) {
	PaError err;

	DEBUG_TRACE("decode_portaudio_start");

	if (!stream) {
		decode_portaudio_openstream();
	}

	if (Pa_IsStreamActive(stream)) {
		/* Stream has started, nothing else to do */
		return;
	}

	if ((err = Pa_StartStream(stream)) != paNoError) {
		DEBUG_ERROR("PA error %s", Pa_GetErrorText(err));
		return;
	}
}


static void decode_portaudio_stop(void) {
	PaError err;

	DEBUG_TRACE("decode_portaudio_stop");

	if (!stream) {
		/* Already stopped */
		return;
	}

	change_sample_rate = false;
	if ((err = Pa_CloseStream(stream)) != paNoError) {
		DEBUG_ERROR("PA error %s", Pa_GetErrorText(err));
		return;
	}

	stream = NULL;
}


static void decode_portaudio_openstream(void) {
	PaError err;

	if (stream) {
		if ((err = Pa_CloseStream(stream)) != paNoError) {
			DEBUG_ERROR("PA error %s", Pa_GetErrorText(err));
		}
	}

	if ((err = Pa_OpenStream(
			&stream,
			NULL,
			&outputParam,
			current_sample_rate,
			paFramesPerBufferUnspecified,
			paPrimeOutputBuffersUsingStreamCallback,
			callback,
			NULL)) != paNoError) {
		DEBUG_ERROR("PA error %s", Pa_GetErrorText(err));
	}

	change_sample_rate = false;
	stream_sample_rate = current_sample_rate;

	/* playout to the end of this stream before changing the sample rate */
	if ((err = Pa_SetStreamFinishedCallback(stream, finished)) != paNoError) {
		DEBUG_ERROR("PA error %s", Pa_GetErrorText(err));
	}

	DEBUG_TRACE("Stream latency %f", Pa_GetStreamInfo(stream)->outputLatency);
	DEBUG_TRACE("Sample rate %f", Pa_GetStreamInfo(stream)->sampleRate);
}


static void decode_portaudio_init(void) {
	PaError err;
	int num_devices, i;
	const PaDeviceInfo *device_info;
	const PaHostApiInfo *host_info;

	if ((err = Pa_Initialize()) != paNoError) {
		goto err;
	}

	DEBUG_TRACE("Portaudio version %s", Pa_GetVersionText());

	memset(&outputParam, 0, sizeof(outputParam));
	outputParam.channelCount = 2;
	outputParam.sampleFormat = paInt24Padded;

	num_devices = Pa_GetDeviceCount();
	for (i = 0; i < num_devices; i++) {
		device_info = Pa_GetDeviceInfo(i);
		host_info = Pa_GetHostApiInfo(device_info->hostApi);

		DEBUG_TRACE("%d: %s (%s)", i, device_info->name, host_info->name);

		outputParam.device = i;

		err = Pa_IsFormatSupported(NULL, &outputParam, 44100);
		if (err == paFormatIsSupported) {
			DEBUG_TRACE("\tsupported");
			break;
		}
		else {
			DEBUG_TRACE("\tnot supported");
		}
	}

	/* high latency for robust playback */
	outputParam.suggestedLatency = Pa_GetDeviceInfo(outputParam.device)->defaultHighOutputLatency;
	return;

 err:
	DEBUG_ERROR("PA error %s", Pa_GetErrorText(err));
	return;
}


struct decode_audio decode_portaudio = {
	decode_portaudio_init,
	decode_portaudio_start,
	decode_portaudio_stop,
};