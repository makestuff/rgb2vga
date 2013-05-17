#include <stdio.h>

#define SCRLEN (640*256/2)

int main(void) {
	FILE *file = fopen("/dev/urandom", "rb");
	//FILE *file = fopen("foo.dat", "rb");
	unsigned char buf[SCRLEN], lsn, msn, byte;
	int i, j, k, x = 0;
	fread(buf, 1, SCRLEN, file);
	fclose(file);

/*	printf("# =====================================================\n# VSYNC front porch (2 lines):\n#");
	for ( i = 0; i < 2; i++ ) {
		printf("\n# -----------------------------------------------------\n# HSYNC pulse, 64px (4us) wide:\n#");
		for ( j = 0; j < 4; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 1 0\n");
			}
		}
		printf("\n# -----------------------------------------------------\n# Remainder of line:\n#");
		for ( j = 4; j < 64; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 0 0\n");
			}
		}
	}

	printf("\n# =====================================================\n# VSYNC pulse (2 lines):\n#");
	for ( i = 0; i < 2; i++ ) {
		printf("\n# -----------------------------------------------------\n# HSYNC pulse, 64px (4us) wide:\n#");
		for ( j = 0; j < 4; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 1 1\n");
			}
		}
		printf("\n# -----------------------------------------------------\n# Remainder of line:\n#");
		for ( j = 4; j < 64; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 0 1\n");
			}
		}
	}

	printf("\n# =====================================================\n# VSYNC back porch (2 lines):\n#");
	for ( i = 0; i < 2; i++ ) {
		printf("\n# -----------------------------------------------------\n# HSYNC pulse, 64px (4us) wide:\n#");
		for ( j = 0; j < 4; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 1 0\n");
			}
		}
		printf("\n# -----------------------------------------------------\n# Remainder of line:\n#");
		for ( j = 4; j < 64; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 0 0\n");
			}
		}
	}
*/

			for ( k = 0; k < 64; k++ ) {
				printf("0 0 0\n");
			}

		printf("\n# -----------------------------------------------------\n# HSYNC pulse, 64px (4us) wide:\n#");
		for ( j = 0; j < 4; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 1 0\n");
			}
		}
		printf("\n# -----------------------------------------------------\n# Remainder of line:\n#");
		for ( j = 4; j < 64; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 0 0\n");
			}
		}

	printf("\n# =====================================================\n# Visible area (256 lines):\n#");
	for ( i = 0; i < 4; i++ ) {
		printf("# -----------------------------------------------------\n# HSYNC pulse, 64px (4us) wide:\n#");
		for ( j = 0; j < 4; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 1 0\n");
			}
		}
		printf("\n# -----------------------------------------------------\n# HSYNC back porch, 192px (12us) wide:\n#");
		for ( j = 4; j < 16; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 0 0\n");
			}
		}
		printf("\n# -----------------------------------------------------\n# Visible region, 640px (40us) wide:\n#");
		for ( j = 16; j < 56; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 8; k++ ) {
				byte = buf[x++];
				lsn = byte & 0x0F;
				msn = byte >> 4;
				printf("%01X 0 0\n", lsn);
				printf("%01X 0 0\n", msn);
			}
		}
		printf("\n# -----------------------------------------------------\n# HSYNC front porch, 128px (8us) wide:\n#");
		for ( j = 56; j < 64; j++ ) {
			printf("\n# Offset %dpx (%dus)\n", j*16, j);
			for ( k = 0; k < 16; k++ ) {
				printf("0 0 0\n");
			}
		}
	}
}
