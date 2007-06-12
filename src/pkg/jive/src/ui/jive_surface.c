/*
** Copyright 2007 Logitech. All Rights Reserved.
**
** This file is subject to the Logitech Public Source License Version 1.0. Please see the LICENCE file for details.
*/


#include "common.h"
#include "jive.h"


#define COLOR_CKEY 0xFF, 0xFF, 0xFF


JiveSurface *jive_surface_set_video_mode(Uint16 w, Uint16 h, Uint16 bpp) {
	JiveSurface *srf;
	SDL_Surface *sdl;

	sdl = SDL_SetVideoMode (w, h, bpp, SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_RESIZABLE);
	if (!sdl) {
		fprintf(stderr, "SDL_SetVideoMode(%d,%d,%d): %s\n",
			w, h, bpp, SDL_GetError());
		return NULL;
	}

	if ( (sdl->flags & SDL_HWSURFACE) == 0) {
		printf("Not using a hardware surface\n");
	}
	else if ( (sdl->flags & SDL_DOUBLEBUF) == 0) {
		printf("WARNING: Not using a hardware double buffer\n");
	}

	srf = calloc(sizeof(JiveSurface), 1);
	srf->refcount = 1;
	srf->sdl = sdl;

	return srf;
}

JiveSurface *jive_surface_newRGB(Uint16 w, Uint16 h) {
	JiveSurface *srf;
	SDL_Surface *sdl;

	sdl = SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, 16, 0, 0, 0, 0);

	/* set color key, paint transparency */
	SDL_SetAlpha(sdl, SDL_SRCALPHA, SDL_ALPHA_OPAQUE);
	SDL_SetColorKey(sdl, SDL_SRCCOLORKEY, SDL_MapRGB(sdl->format, COLOR_CKEY));
	SDL_FillRect(sdl, 0, SDL_MapRGB(sdl->format, COLOR_CKEY));

	srf = calloc(sizeof(JiveSurface), 1);
	srf->refcount = 1;
	srf->sdl = sdl;

	return srf;
}


JiveSurface *jive_surface_newRGBA(Uint16 w, Uint16 h) {
	JiveSurface *srf;
	SDL_Surface *sdl;

	/*
	 * Work out the optimium pixel masks for the display with
	 * 32bit alpha surfaces. If we get this wrong a non-optimised
	 * blitter will be used.
	 */
	const SDL_VideoInfo *video_info = SDL_GetVideoInfo();
	if (video_info->vfmt->Rmask < video_info->vfmt->Bmask) {
		sdl = SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, 32,
					   0x000000FF, 0x0000FF00, 0x00FF0000, 0xFF000000);
	}
	else {
		sdl = SDL_CreateRGBSurface(SDL_SWSURFACE, w, h, 32,
					   0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000);
	}

	/* alpha channel, paint transparency */
	SDL_SetAlpha(sdl, SDL_SRCALPHA, SDL_ALPHA_OPAQUE);

	srf = calloc(sizeof(JiveSurface), 1);
	srf->refcount = 1;
	srf->sdl = sdl;

	return srf;
}


JiveSurface *jive_surface_ref(JiveSurface *srf) {
	if (srf) {
		srf->refcount++;
	}
	return srf;
}


/*
 * Convert image to best format for display on the screen
 */
JiveSurface *jive_surface_display_format(JiveSurface *srf, bool is_alpha) {
	SDL_Surface *sdl;

	if (srf->sdl == NULL) {
		return srf;
	}

	if (is_alpha) {
		sdl = SDL_DisplayFormatAlpha(srf->sdl);
	}
	else {
		sdl = SDL_DisplayFormat(srf->sdl);
	}
	SDL_FreeSurface(srf->sdl);
	srf->sdl = sdl;

	return srf;
}


JiveSurface *jive_surface_load_image(const char *path) {
	char *fullpath;
	JiveSurface *srf;
	SDL_Surface *sdl;

	if (!path) {
		return NULL;
	}

	fullpath = malloc(PATH_MAX);
	if (!jive_find_file(path, fullpath)) {
		fprintf(stderr, "Cannot find image %s\n", path);
		free(fullpath);
		return NULL;
	}

	sdl = IMG_Load(fullpath);
	if (!sdl) {
		fprintf(stderr, "Error in jive_surface_load_image: %s\n", IMG_GetError());
	}

	free(fullpath);

	srf = calloc(sizeof(JiveSurface), 1);
	srf->refcount = 1;
	srf->sdl = sdl;

	return jive_surface_display_format(srf, true);
}


JiveSurface *jive_surface_load_image_data(const char *data, size_t len) {
	SDL_RWops *src = SDL_RWFromConstMem(data, (int) len);
	SDL_Surface *sdl = IMG_Load_RW(src, 1);

	JiveSurface *srf = calloc(sizeof(JiveSurface), 1);
	srf->refcount = 1;
	srf->sdl = sdl;

	return jive_surface_display_format(srf, false);
}

void jive_surface_set_offset(JiveSurface *srf, Sint16 x, Sint16 y) {
	srf->offset_x = x;
	srf->offset_y = y;
}

void jive_surface_get_clip(JiveSurface *srf, SDL_Rect *r) {
	SDL_GetClipRect(srf->sdl, r);

	r->x -= srf->offset_x;
	r->y -= srf->offset_y;
}

void jive_surface_set_clip(JiveSurface *srf, SDL_Rect *r) {
	SDL_Rect tmp;

	if (r) {
		tmp.x = r->x + srf->offset_x;
		tmp.y = r->y + srf->offset_y;
		tmp.w = r->w;
		tmp.h = r->h;
	}
	else {
		tmp.x = 0;
		tmp.y = 0;
		tmp.w = srf->sdl->w;
		tmp.h = srf->sdl->h;
	}

	SDL_SetClipRect(srf->sdl, &tmp);
}

void jive_surface_set_clip_arg(JiveSurface *srf, Uint16 x, Uint16 y, Uint16 w, Uint16 h) {
	SDL_Rect tmp;

	tmp.x = x + srf->offset_x;
	tmp.y = y + srf->offset_y;
	tmp.w = w;
	tmp.h = h;

	SDL_SetClipRect(srf->sdl, &tmp);
}

void jive_surface_get_clip_arg(JiveSurface *srf, Uint16 *x, Uint16 *y, Uint16 *w, Uint16 *h) {
	SDL_Rect tmp;

	SDL_GetClipRect(srf->sdl, &tmp);

	*x = tmp.x - srf->offset_x;
	*y = tmp.y - srf->offset_y;
	*w = tmp.w;
	*h = tmp.h;
}

void jive_surface_flip(JiveSurface *srf) {
	SDL_Flip(srf->sdl);
}

void jive_surface_blit(JiveSurface *src, JiveSurface *dst, Uint16 dx, Uint16 dy) {
	SDL_Rect dr;
	dr.x = dx + dst->offset_x;
	dr.y = dy + dst->offset_y;
	SDL_BlitSurface(src->sdl, 0, dst->sdl, &dr);
}


void jive_surface_blit_clip(JiveSurface *src, Uint16 sx, Uint16 sy, Uint16 sw, Uint16 sh,
			  JiveSurface* dst, Uint16 dx, Uint16 dy) {
	SDL_Rect sr, dr;
	sr.x = sx; sr.y = sy; sr.w = sw; sr.h = sh;
	dr.x = dx + dst->offset_x; dr.y = dy + dst->offset_y;
	SDL_BlitSurface(src->sdl, &sr, dst->sdl, &dr);
}


void jive_surface_get_size(JiveSurface *srf, Uint16 *w, Uint16 *h) {
	if (w) {
		*w = (srf->sdl) ? srf->sdl->w : 0;
	}
	if (h) {
		*h = (srf->sdl) ? srf->sdl->h : 0;
	}
}

void jive_surface_free(JiveSurface *srf) {
	if (--srf->refcount > 0) {
		return;
	}

	if (srf->sdl) {
		SDL_FreeSurface (srf->sdl);
		srf->sdl = NULL;
	}
	free(srf);
}


/* SDL_gfx encapsulated functions */
JiveSurface *jive_surface_rotozoomSurface(JiveSurface *srf, double angle, double zoom, int smooth){
	JiveSurface *srf2;

	srf2 = calloc(sizeof(JiveSurface), 1);
	srf2->refcount = 1;
	srf2->sdl = rotozoomSurface(srf->sdl, angle, zoom, smooth);

	return srf2;
}

JiveSurface *jive_surface_zoomSurface(JiveSurface *srf, double zoomx, double zoomy, int smooth) {
	JiveSurface *srf2;

	srf2 = calloc(sizeof(JiveSurface), 1);
	srf2->refcount = 1;
	srf2->sdl = zoomSurface(srf->sdl, zoomx, zoomy, smooth);

	return srf2;
}

JiveSurface *jive_surface_shrinkSurface(JiveSurface *srf, int factorx, int factory) {
	JiveSurface *srf2;

	srf2 = calloc(sizeof(JiveSurface), 1);
	srf2->refcount = 1;
	srf2->sdl = shrinkSurface(srf->sdl, factorx, factory);

	return srf2;
}


void jive_surface_pixelColor(JiveSurface *srf, Sint16 x, Sint16 y, Uint32 color) {
	pixelColor(srf->sdl,
		   x + srf->offset_x,
		   y + srf->offset_y,
		   color);
}

void jive_surface_hlineColor(JiveSurface *srf, Sint16 x1, Sint16 x2, Sint16 y, Uint32 color) {
	hlineColor(srf->sdl,
		   x1 + srf->offset_x,
		   x2 + srf->offset_x,
		   y + srf->offset_y,
		   color);
}

void jive_surface_vlineColor(JiveSurface *srf, Sint16 x, Sint16 y1, Sint16 y2, Uint32 color) {
	vlineColor(srf->sdl,
		   x + srf->offset_x,
		   y1 + srf->offset_y,
		   y2 + srf->offset_y,
		   color);
}

void jive_surface_rectangleColor(JiveSurface *srf, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 col) {
	rectangleColor(srf->sdl,
		       x1 + srf->offset_x,
		       y1 + srf->offset_y,
		       x2 + srf->offset_x,
		       y2 + srf->offset_y,
		       col);
}

void jive_surface_boxColor(JiveSurface *srf, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 col) {
	boxColor(srf->sdl,
		 x1 + srf->offset_x,
		 y1 + srf->offset_y,
		 x2 + srf->offset_x,
		 y2 + srf->offset_y,
		 col);
}

void jive_surface_lineColor(JiveSurface *srf, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 col) {
	lineColor(srf->sdl,
		  x1 + srf->offset_x,
		  y1 + srf->offset_y,
		  x2 + srf->offset_x,
		  y2 + srf->offset_y,
		  col);
}

void jive_surface_aalineColor(JiveSurface *srf, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Uint32 col) {
	aalineColor(srf->sdl,
		    x1 + srf->offset_x,
		    y1 + srf->offset_y,
		    x2 + srf->offset_x,
		    y2 + srf->offset_y,
		    col);
}

void jive_surface_circleColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 r, Uint32 col) {
	circleColor(srf->sdl,
		    x + srf->offset_x,
		    y + srf->offset_y,
		    r,
		    col);
}

void jive_surface_aacircleColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 r, Uint32 col) {
	aacircleColor(srf->sdl,
		      x + srf->offset_x,
		      y + srf->offset_y,
		      r,
		      col);
}

void jive_surface_filledCircleColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 r, Uint32 col) {
	filledCircleColor(srf->sdl,
			  x + srf->offset_x,
			  y + srf->offset_y,
			  r,
			  col);
}

void jive_surface_ellipseColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 col) {
	ellipseColor(srf->sdl,
		     x + srf->offset_x,
		     y + srf->offset_y,
		     rx,
		     ry,
		     col);
}

void jive_surface_aaellipseColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 col) {
	aaellipseColor(srf->sdl,
		       x + srf->offset_x,
		       y + srf->offset_y,
		       rx,
		       ry,
		       col);
}

void jive_surface_filledEllipseColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 rx, Sint16 ry, Uint32 col) {
	filledEllipseColor(srf->sdl,
			   x + srf->offset_x,
			   y + srf->offset_y,
			   rx,
			   ry,
			   col);
}

void jive_surface_pieColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 rad, Sint16 start, Sint16 end, Uint32 col) {
	pieColor(srf->sdl,
		 x + srf->offset_x,
		 y + srf->offset_y,
		 rad,
		 start,
		 end,
		 col);
}

void jive_surface_filledPieColor(JiveSurface *srf, Sint16 x, Sint16 y, Sint16 rad, Sint16 start, Sint16 end, Uint32 col) {
	filledPieColor(srf->sdl,
		       x + srf->offset_x,
		       y + srf->offset_y,
		       rad,
		       start,
		       end,
		       col);
}

void jive_surface_trigonColor(JiveSurface *srf, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Sint16 x3, Sint16 y3, Uint32 col) {
	trigonColor(srf->sdl,
		    x1 + srf->offset_x,
		    y1 + srf->offset_y,
		    x2 + srf->offset_x,
		    y2 + srf->offset_y,
		    x3 + srf->offset_x,
		    y3 + srf->offset_y,
		    col);
}

void jive_surface_aatrigonColor(JiveSurface *srf, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Sint16 x3, Sint16 y3, Uint32 col) {
	aatrigonColor(srf->sdl,
		      x1 + srf->offset_x,
		      y1 + srf->offset_y,
		      x2 + srf->offset_x,
		      y2 + srf->offset_y,
		      x3 + srf->offset_x,
		      y3 + srf->offset_y,
		      col);
}

void jive_surface_filledTrigonColor(JiveSurface *srf, Sint16 x1, Sint16 y1, Sint16 x2, Sint16 y2, Sint16 x3, Sint16 y3, Uint32 col) {
	filledTrigonColor(srf->sdl,
			  x1 + srf->offset_x,
			  y1 + srf->offset_y,
			  x2 + srf->offset_x,
			  y2 + srf->offset_y,
			  x3 + srf->offset_x,
			  y3 + srf->offset_y,
			  col);
}
