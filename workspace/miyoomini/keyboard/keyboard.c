#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_ttf.h>

#include <fcntl.h>
#include <linux/input.h>
#include <linux/fb.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

/*
 * This code is garbage but it works so whatever I guess
 * 
 * usage: keyboard [prompt] [maxlength] > result.txt
 *
 */

#define PINK_TRIAD  0xd4,0x98,0xab
#define kLineHeight 48
#define kCharWidth  28

#define BUTTON_A       KEY_SPACE
#define BUTTON_B       KEY_LEFTCTRL
#define BUTTON_X       KEY_LEFTSHIFT
#define BUTTON_Y       KEY_LEFTALT
#define BUTTON_L1      KEY_E
#define BUTTON_R1      KEY_T
#define BUTTON_L2      KEY_TAB
#define BUTTON_R2      KEY_BACKSPACE
#define BUTTON_START   KEY_ENTER
#define BUTTON_SELECT  KEY_RIGHTCTRL
#define BUTTON_MENU    KEY_ESC

#define FONT_PATH "/mnt/SDCARD/.system/res/SpaceMono-Bold.ttf"

static char* str = 0;
static char* prompt = 0;
static unsigned int max_len = 135;

// kbd[63]
static char kbd[] = {'Q','W','E','R','T','Y','U','I','O','P','0','1','2','3','4','5','6','7','8','9','=',
'A','S','D','F','G','H','J','K','L','!','#','%','&','\'','(',')',':',';','|','*','~',
'Z','X','C','V','B','N','M',' ',',','.','-','_','<','>','=','@','^','`','{','}','/'};

static char kbd_alt[] = {'q','w','e','r','t','y','u','i','o','p','0','1','2','3','4','5','6','7','8','9','=',
'a','s','d','f','g','h','j','k','l','!','#','%','&','\'','(',')',':',';','|','*','~',
'z','x','c','v','b','n','m',' ',',','.','-','_','<','>','=','@','^','`','{','}','/'};

static void blit(void* _dst, int dst_w, int dst_h, void* _src, int src_w, int src_h, int ox, int oy) {
	uint8_t* dst = (uint8_t*)_dst;
	uint8_t* src = (uint8_t*)_src;

	oy += kLineHeight - src_h;

	for (int y=0; y<src_h; y++) {
		uint8_t* dst_row = dst + (((((dst_h - 1 - oy) - y) * dst_w) - 1 - ox) * 4);
		uint8_t* src_row = src + ((y * src_w) * 4);
		for (int x=0; x<src_w; x++) {
			float a = *(src_row+3) / 255.0;
			if (a>0.1) {
				*(dst_row+0) = *(src_row+0) * a;
				*(dst_row+1) = *(src_row+1) * a;
				*(dst_row+2) = *(src_row+2) * a;
				*(dst_row+3) = 0xff;
			}
			dst_row -= 4;
			src_row += 4;
		}
	}
}

static void fill(void* _dst, int w, int h, int ox, int oy, uint32_t pixel) {
	uint32_t* dst = (uint32_t*)_dst;
	for (int y=0; y<h; y++)
		for (int x=0; x<w; x++)
			*(dst+(640-x-ox)+(640*(480-y-oy-h))) = pixel;
}

static void push(char c) {
	for (unsigned int i = 0; i < max_len; i++) {
		if (!str[i]) {
			str[i] = c;
			str[i+1] = 0;
			return;
		}
	}
}

static void back() {
	int i = 0;
	while (str[i]) i++;
	if (i-- > 0) {
		str[i] = 0;
	}
}

static void printstr(void* fb0_map, TTF_Font* font, SDL_Color color) {
	SDL_Surface* text;
	int a = 0;
	int y = 72;
	int x = 40;
	char line[28];
	for (unsigned int i = 0; i < max_len && str[i]; i++) {
		line[a] = str[i];
		a++;
		if (a >= 27) {
			line[27] = 0;
			text = TTF_RenderUTF8_Blended(font, line, color);
			fill(fb0_map, kCharWidth, kLineHeight, x-kCharWidth+text->w+5, y-kLineHeight, 0xFF444444);
			fill(fb0_map, kCharWidth, kLineHeight, x+text->w+5, y-kLineHeight, 0xFF000000);
			blit(fb0_map,640,480,text->pixels,text->w,text->h,x,y);
			SDL_FreeSurface(text);
			a = 0;
			y += kLineHeight;
		}
	}
	if (a) {
		line[a] = 0;
		text = TTF_RenderUTF8_Blended(font, line, color);
		fill(fb0_map, kCharWidth, kLineHeight, x-kCharWidth+text->w+5, y-kLineHeight, 0xFF444444);
		fill(fb0_map, kCharWidth, kLineHeight, x+text->w+5, y-kLineHeight, 0xFF000000);
		blit(fb0_map,640,480,text->pixels,text->w,text->h,x,y);
		SDL_FreeSurface(text);
	} else if (y < 72+kLineHeight*5) {
		fill(fb0_map, kCharWidth+10, kLineHeight, x-5, y-kLineHeight, 0xFF000000);
	}
}

int main(int argc , char* argv[]) {
	static const char* font_path = FONT_PATH;
	if (access(font_path, F_OK)) {
		font_path = "SpaceMono-Bold.ttf";
		if (access(font_path, F_OK)) {
			font_path = "./SpaceMono-Bold.ttf";
			if (access(font_path, F_OK)) return -1;
		}
	}

	if (argc > 1) {
		unsigned int plen = strlen(argv[1]);
		if (plen) {
			if (plen > 27) plen = 27;
			prompt = (char*)malloc(plen+1);
			if (!prompt) return -1;
			strncpy(prompt, argv[1], plen);
			prompt[plen] = 0;
		}
		if (argc > 2) {
			max_len = atoi(argv[2]);
			if (max_len > 135) max_len = 135;
		}
	}
	str = (char*)malloc(max_len+1);
	if (!str) return -1;
	*str = 0;

	int fb0_fd = open("/dev/fb0", O_RDWR);
	if (fb0_fd == -1) return -1;
	struct fb_var_screeninfo vinfo;
	ioctl(fb0_fd, FBIOGET_VSCREENINFO, &vinfo);
	int map_size = vinfo.xres * vinfo.yres * (vinfo.bits_per_pixel / 8); // 640x480x4
	char* fb0_map = (char*)mmap(0, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fb0_fd, 0);
	if (fb0_map == (void*)-1) { close(fb0_fd); return -1; }
	memset(fb0_map, 0, map_size);

	if (TTF_Init()) { munmap(fb0_map, map_size); close(fb0_fd); return -1; }
	TTF_Font* font = TTF_OpenFont(font_path, 32);
	if (font == NULL) { TTF_Quit(); munmap(fb0_map, map_size); close(fb0_fd); return -1; }
	//TTF_SetFontKerning(font, 0);

	SDL_Color pink = {PINK_TRIAD};
	SDL_Color white = {255,255,255};
	SDL_Surface* text;

	if (prompt) {
		text = TTF_RenderUTF8_Blended(font, prompt, pink);
		blit(fb0_map,640,480,text->pixels,text->w,text->h,30,16);
		SDL_FreeSurface(text);
	}

	unsigned int alt = 0;
	unsigned int key = 0;
	unsigned int prev_key = 1;
	unsigned int dirty = 1;
	int quit = -1;
	int input_fd = open("/dev/input/event0", O_RDONLY);
	struct input_event event;
	if (input_fd != -1) {
		while (quit < 0) {
			int y = (480-kLineHeight*3)-24;
			int x = 30;
			for (int i=0; i < sizeof(kbd); i++) {
				if (dirty || i == key || i == prev_key) {
					if (kbd[i] == ' ') {
						fill(fb0_map, 20, 32, x, y-10, (i == key) ? 0xFFFFFFFF : 0);
					} else {
						text = TTF_RenderGlyph_Blended(font, alt ? kbd_alt[i] : kbd[i], (key == i) ? white : pink);
						int miny;
						TTF_GlyphMetrics(font, alt ? kbd_alt[i] : kbd[i], 0, 0, &miny, 0, 0);
						blit(fb0_map,640,480,text->pixels,text->w,text->h,x,y-miny);
						SDL_FreeSurface(text);
					}
				}
				x += kCharWidth;
				if (i == 20 || i == 41) {
					y += kLineHeight;
					x = 30;
				}
			}
			dirty = 0;
			while (read(input_fd, &event, sizeof(event))==sizeof(event)) {
				if (event.type==EV_KEY) {
					if (event.code==BUTTON_MENU || event.code==KEY_POWER) {
						quit = 1;
						break;
					} else if (event.value==1 || event.value==2) {
						if (event.code==KEY_UP) {
							prev_key = key;
							if (key > 20) key -= 21;
							else key += 42;
							break;
						} else if (event.code==KEY_DOWN) {
							prev_key = key;
							if (key < 42) key += 21;
							else key -= 42;
							break;
						} else if (event.code==KEY_LEFT) {
							prev_key = key;
							if (key == 0) key = 62;
							else key--;
							break;
						} else if (event.code==KEY_RIGHT) {
							prev_key = key;
							if (key > 61) key = 0;
							else key++;
							break;
						} else if (event.code==BUTTON_B) {
							back();
							printstr(fb0_map, font, white);
							break;
						} else if (event.value==1) {
							if (event.code==BUTTON_X || event.code==BUTTON_L1 || event.code==BUTTON_R1 ||
									event.code==BUTTON_L2 || event.code==BUTTON_R2 || event.code==BUTTON_SELECT) {
								memset(fb0_map+(640*24*4), 0, 640*kLineHeight*3*4);
								dirty = 1;
								alt = !alt;
								break;
							} else if (event.code==BUTTON_A) {
								push(alt ? kbd_alt[key] : kbd[key]);
								printstr(fb0_map, font, white);
								break;
							} else if (event.code==BUTTON_Y) {
								push(' ');
								printstr(fb0_map, font, white);
								break;
							}
						}
					} else if (event.value==0 && event.code==BUTTON_START) {
						quit = 0;
						break;
					}
				}
			}
		}
	}
	close(input_fd);
	TTF_CloseFont(font);
	TTF_Quit();
	munmap(fb0_map, map_size);
	close(fb0_fd);

	if (quit==0) puts(str);
	free(str);

	return quit;
}
