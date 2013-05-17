/* 
 * Copyright (C) 2012 Chris McClelland
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *  
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <stdio.h>
#include <sys/time.h>
#include <SDL/SDL.h>
#include <makestuff.h>
#include "palette.h"

#define SCREEN_WIDTH  1100
#define SCREEN_HEIGHT 300
//#define DOUBLE

void drawPixel(uint16 x, uint16 y, uint8 colour, const SDL_Surface *surface) {
	#ifdef DOUBLE
		uint8 *const pixels = (uint8 *)surface->pixels + y * SCREEN_WIDTH * 4 + x * 2;
		pixels[1] = colour;
		pixels[2*SCREEN_WIDTH] = colour;
		pixels[2*SCREEN_WIDTH + 1] = colour;
	#else
		uint8 *const pixels = (uint8 *)surface->pixels + y * SCREEN_WIDTH + x;
	#endif
	pixels[0] = colour;
}

void doRender(const uint8 *const rawCapture, SDL_Surface *surface, SDL_Surface *screen) {
	const uint8 *ptr = rawCapture;
	uint16 x = 0, y = 0, i;
	uint8 thisPix, nextPix;
	char fileName[17];
	for ( i = 0; i < 2; i++ ) {
		while ( !((ptr[0] & 0x10) == 0x00 && (ptr[1] & 0x10) == 0x10) ) {
			ptr++;
		}
		while ( !((ptr[0] & 0x08) == 0x08 && (ptr[-1] & 0x08) == 0x00) ) {
			ptr--;
		}
		printf("Found frame at %zd\n", ptr - rawCapture);
		
		for ( y = 0; y < 300; y++ ) {
			x = 0;
			printf("Line %d: start@0x%08X; length ", y, (uint32)(ptr-rawCapture));
			do {
				thisPix = ptr[0];
				nextPix = ptr[1];
				drawPixel(x, y, thisPix, surface);
				x++;
				ptr++;
			} while ( x < 1100 && !((thisPix & 0x08) == 0x00 && (nextPix & 0x08) == 0x08) );
			if ( x == 1100 ) {
				printf("too long!\n");
				exit(1);
			} else {
				printf("%d (end@0x%08X)\n", x, (uint32)(ptr-rawCapture));
			}
			while ( x < 1100 ) {
				//printf(".");
				drawPixel(x, y, 15, surface);
				x++;
			}
			//printf("\n");
		}
		SDL_BlitSurface(surface, NULL, screen, NULL);
		snprintf(fileName, 17, "f%04d.bmp", i);
		SDL_SaveBMP(surface, fileName);
		SDL_Flip(screen);
	}
}

SDL_Surface *createSurface(Uint32 flags, const SDL_Surface *display) {
	const SDL_PixelFormat *fmt = display->format;
	return SDL_CreateRGBSurface(
		flags,
		display->w,
		display->h,
		fmt->BitsPerPixel,
		fmt->Rmask,
		fmt->Gmask,
		fmt->Bmask,
		fmt->Amask
	);
}

#define SDLCHECK(condition, message, code)      \
	if ( condition ) {                           \
		fprintf(stderr, message, SDL_GetError()); \
		returnCode = code;                        \
		goto cleanup;                             \
	}
#define CHECK(condition, message, code)         \
	if ( condition ) {                           \
		fprintf(stderr, message);                 \
		returnCode = code;                        \
		goto cleanup;                             \
	}

void waitClick(void) {
	SDL_Event event;
	for ( ; ; ) {
		while ( SDL_PollEvent(&event) ) {
			switch (event.type) {
			case SDL_KEYDOWN:
				printf(
					"The %s key was pressed!\n", SDL_GetKeyName(event.key.keysym.sym));
				break;
			case SDL_QUIT:
				return;
			}
		}
	}
}

//int main(int argc, const char *args[]) {
int main(void) {
	int returnCode = 0;
	SDL_Surface *surface = NULL;
	SDL_Surface *screen = NULL;
	SDL_Color colors[256];
	int i;
	const unsigned char *p = palette;
	unsigned char *captureData = NULL;
	FILE *captureFile = NULL;
	size_t readLength;

	captureData = malloc(640096);
	CHECK(!captureData, "Couldn't allocate memory for capture buffer!\n", 1);
	captureFile = fopen("/dev/stdin", "rb");
	//captureFile = fopen("/home/chris/makestuff/hdlmake/apps/makestuff/sample8/vhdl/mode0.dat", "rb");
	CHECK(!captureFile, "Couldn't open capture file!\n", 2);
	readLength = fread(captureData, 1, 640096, captureFile);
	CHECK(readLength != 640096, "Couldn't read capture data!\n", 3);

	// Start SDL
	SDL_Init(SDL_INIT_EVERYTHING);

	// Set up screen
	screen = SDL_SetVideoMode(
		#ifdef DOUBLE
			SCREEN_WIDTH * 2,
			SCREEN_HEIGHT * 2,
		#else
			SCREEN_WIDTH,
			SCREEN_HEIGHT,
		#endif
		8,
		SDL_HWSURFACE | SDL_HWPALETTE | SDL_DOUBLEBUF // | SDL_ASYNCBLIT
		// | SDL_FULLSCREEN
	);
	SDLCHECK(!screen, "Couldn't set video mode: %s\n", 1);

	// Build the palette
	for ( i = 0; i < 256; i++ ) {
		colors[i].r = *p++;
		colors[i].g = *p++;
		colors[i].b = *p++;
	}

	// Create surface to work with, and set the palette
	surface = createSurface(SDL_SWSURFACE, screen);
	SDL_SetPalette(surface, SDL_LOGPAL|SDL_PHYSPAL, colors, 0, 256);
	SDL_SetPalette(screen, SDL_LOGPAL|SDL_PHYSPAL, colors, 0, 256);

	doRender(captureData, surface, screen);

	// Pause
	//waitClick();

cleanup:
	// Clean capture data & file
	if ( captureData ) {
		free(captureData);
	}
	if ( captureFile ) {
		fclose(captureFile);
	}

	// Free the loaded image
	SDL_FreeSurface(surface);

	// Quit SDL
	SDL_Quit();

	return returnCode;
}
