/////////////////////////////////////////////////////////////////////////
// $Id: nogui.cc,v 1.23 2006/02/21 21:35:08 vruppert Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2001  MandrakeSoft S.A.
//
//    MandrakeSoft S.A.
//    43, rue d'Aboukir
//    75002 Paris - France
//    http://www.linux-mandrake.com/
//    http://www.mandrakesoft.com/
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA



// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE 
// is used to know when we are exporting symbols and when we are importing.

#define BX_PLUGGABLE

#import "bochs.h"
#import "param_names.h"
#import "keymap.h"
#import "iodev.h"
#if BX_WITH_NOGUI
#import "icon_bochs.h"
#import "iodev.h"
#import <time.h>
#import <math.h>

#import <UIKit/UIKit.h>
#import <BochsKit/BXRenderView.h>

class bx_nogui_gui_c : public bx_gui_c 
{
public:
	bx_nogui_gui_c (void) {}
	void show_ips(Bit32u ips_count);

	DECLARE_GUI_VIRTUAL_METHODS()
};

// declare one instance of the gui object and call macro to insert the
// plugin code
static bx_nogui_gui_c *theGui = NULL;


IMPLEMENT_GUI_PLUGIN_CODE(nogui)

#define LOG_THIS theGui->
#define BX_GUI_THIS theGui->

#define MAX_EVENTS 100

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////

typedef struct _EventStruct
{
	int isMouse;
	int x;
	int y;
	int button;
} EventStruct;

static BXRenderView* renderView;
static int tsx, tsy;
static bool isTextMode;
static unsigned short textBuffer[80*26];
static int currentResX, currentResY, currentBpp;
static EventStruct eventBuffer[MAX_EVENTS];
static int eventBufferPos;
static unsigned indexed_colors[256][3];
static int touchX, touchY, touchCount;
static bool quickTap;
static long prevTime, oldTime;
static int prevX, prevY;
static int averageWidth = 0, averageHeight = 12, currentState = -1;
static float fwidth, fheight, ratio = 480.0f / 320.0f;
static NSDate *date = [NSDate date];

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////


@implementation BXRenderView

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        renderView = [[self alloc] init];
    });
    
    return renderView;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        imageData = nil;
        imageContext = nil;
        
        self.backgroundColor = [UIColor blackColor];
        
        isTextMode = YES;
        
        [self recreateImageContextWithX:800 y:600 bpp:16];
        
    }
    return self;
}

- (id)init:(UIWindow*)window
{
	self = [super initWithFrame:CGRectMake(0, 0, 480, 320)];
	self.transform = CGAffineTransformMakeRotation(3.1415926/2);
	self.transform = CGAffineTransformTranslate(self.transform, 80, 80);
	self.multipleTouchEnabled = YES;

	renderView = self;
	
	imageData = nil;
	imageContext = nil;
	
	self.backgroundColor = [UIColor blackColor];
	
	isTextMode = YES;
	
	[self recreateImageContextWithX:800 y:600 bpp:16];
	
	[self addToWindow:window];
	
	return self;
}

- (void)addToWindow:(UIWindow*)window
{
	[window addSubview:self];	
}

- (void)recreateImageContextWithX:(int)x y:(int)y bpp:(int)bpp
{	
	sz.width = x;
	sz.height = y;
	
	currentResX = sz.width;
	currentResY = sz.height;

	@synchronized(self)
	{
		if (imageContext)
		{
			CGContextRelease(imageContext);
			imageContext = nil;
		}
	 
		if (imageData)
		{
			free(imageData);
			imageData = nil;
		}
	 
		imageData = (int*)malloc(sz.width * sz.height * 4);
		imageContext = CGBitmapContextCreate(imageData, sz.width, sz.height, 8, sz.width*4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaNoneSkipLast);
	}
	
	CGContextSetRGBFillColor(imageContext, 0.5f, 0.5f, 0.5f, 1.0f);
	CGContextFillRect(imageContext, CGRectMake(0, 0, sz.width, sz.height));
	
}

- (void)doRedraw
{
	if (self.superview)
	{
		[self setNeedsDisplay];
	}
}

- (void)rescaleFrame
{
    currentState = -1;
}

void addToEventBuffer(int isMouse, int x, int y, int button)
{
    if (eventBufferPos >= MAX_EVENTS-1)
        return;
    
    int oldX = 0;
    int oldY = 0;
    
    if (eventBufferPos)
    {
        eventBufferPos = 0;
        oldX = eventBuffer[0].x;
        oldY = eventBuffer[0].y;
    }
    
    eventBuffer[eventBufferPos].isMouse = isMouse;
    eventBuffer[eventBufferPos].x = oldX + x;//(int)(x*1.5f);
    eventBuffer[eventBufferPos].y = oldY - y;//-(int)(y*1.5f);
    eventBuffer[eventBufferPos].button = button;
    eventBufferPos++;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	for (UITouch* touch in touches)
	{
		if (touchCount == 0)
		{
			CGPoint p = [touch locationInView:self];

			touchX = p.x;
			touchY = p.y;
		}
		touchCount++;
	}
    if(oldTime > 0 && touchCount == 1) {
        if(-[date timeIntervalSinceNow]*1000 <= oldTime) {
            oldTime = 0;
            quickTap = YES;
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{

	for (UITouch* touch in touches)
	{
		CGPoint p = [touch locationInView:self];
		CGPoint pOld = [touch previousLocationInView:self];
		
        addToEventBuffer(1, p.x - pOld.x, p.y - pOld.y, quickTap == YES ? 1 : 0);
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event //messy, needs a rewrite
{
    int isTap = 0;
	for (UITouch* touch in touches)
	{
		CGPoint p = [touch locationInView:self];
		CGPoint pOld = [touch previousLocationInView:self];
        if ((abs(p.x - touchX) < 5) && (abs(p.y-touchY) < 5) && isTap == 0 && quickTap == NO) {
            prevTime = -[date timeIntervalSinceNow]*1000 + 10;
            if (touches.count == 2 || touchCount == 2) {
                isTap = 2;
            } else {
                isTap = 1;
                oldTime = prevTime + 270;
            }
            prevX = p.x - pOld.x;
            prevY = p.y - pOld.y;
            
        }
        touchCount--;
        if(isTap >= 0) {
            addToEventBuffer(1, p.x - pOld.x, p.y - pOld.y, isTap);
            isTap = -1;
        }
	}
    quickTap = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)drawRect:(CGRect)rect 
{
	@synchronized(self)
	{
		@autoreleasepool {
		
            CGContextRef c = UIGraphicsGetCurrentContext();
            CGContextSaveGState(c);
            //res is 480x320
            
            if(currentState == 0 && self.frame.size.height < self.frame.size.width) {
                currentState = 1;
                averageWidth = 0;
                fwidth = self.frame.size.height * ratio;
                fheight = self.frame.size.height;
            } else if((currentState == 1 && self.frame.size.width < self.frame.size.height) || currentState == -1) {
                currentState = 0;
                averageWidth = 0;
                fwidth = self.frame.size.width;
                fheight = self.frame.size.width / ratio;
            }
        
            CGContextTranslateCTM(c, self.frame.size.width / 2 - fwidth / 2, self.frame.size.height / 2 + fheight / 2);
            CGContextScaleCTM(c, fwidth / self.frame.size.width, -fheight / self.frame.size.height);
            
            CGImageRef image = CGBitmapContextCreateImage(imageContext);
            if (image)
            {
                CGContextDrawImage(c, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height), image);
                CGImageRelease(image);
            }
            
            if(isTextMode) {
                CGContextRestoreGState(c);
                CGContextSaveGState(c);
                CGContextTranslateCTM(c, self.frame.size.width / 2 - fwidth / 2, self.frame.size.height / 2 - fheight / 2);
                UIFont* font = [UIFont fontWithName:@"Courier" size:averageHeight];
                NSDictionary * fontAttributes = @{NSFontAttributeName: font,
                                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
				
                if(averageWidth == 0) {
                    averageHeight = (fwidth / 60) / 0.63; //60 char width for now, (too small on some displays)
                    averageWidth = averageHeight * 0.63;
                } else {
                    for (int y = 0; y < 25; y++)
                    {
                        for (int x = 0; x < 80; x++)
                        {
                            unichar ch = textBuffer[x + y*80] & 0xff;
                            
                            NSString * s = [[NSString alloc] initWithCharacters:&ch length:1];
                            [s drawAtPoint:CGPointMake(x * averageWidth, y * averageHeight) withAttributes:fontAttributes];
                        }
                    }
                }
				
                CGContextRestoreGState(c);
			}
		
		}
	}
}

- (int*)imageData
{
	return imageData;
}

- (CGContextRef)imageContext
{
	return imageContext;
}

- (void)vKeyDown:(int)keyCode
{
    DEV_kbd_gen_scancode(keyCode|BX_KEY_PRESSED);
}

- (void)vKeyUp:(int)keyCode
{
    DEV_kbd_gen_scancode(keyCode|BX_KEY_RELEASED);
}


@end

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////


void bx_nogui_gui_c::specific_init(int argc, char **argv, unsigned tilewidth, unsigned tileheight, unsigned headerbar_y)
{
	BX_GUI_THIS new_gfx_api = 0;
	BX_GUI_THIS host_xres = 800;
	BX_GUI_THIS host_yres = 600;
	BX_GUI_THIS host_bpp = 32;
	
	tsx = tilewidth;
	tsy = tileheight;
}

void bx_nogui_gui_c::handle_events(void)
{
    if(prevTime > 0) {
        if(-[date timeIntervalSinceNow]*1000 >= prevTime) {
            prevTime = 0;
            addToEventBuffer(1, prevX, prevY, 0);
        }
    }
	while(eventBufferPos)
	{
		eventBufferPos--;
		if (eventBuffer[eventBufferPos].isMouse)
		{
            int buttons = 0;
            //Stolen from SVGA :)
            if (eventBuffer[eventBufferPos].button == 1) {
                buttons |= 0x01;
            }
            if (eventBuffer[eventBufferPos].button == 2) {
                buttons |= 0x02;
            }
			DEV_mouse_motion(eventBuffer[eventBufferPos].x, eventBuffer[eventBufferPos].y, 0, buttons, 0);
		}
	}
}

void bx_nogui_gui_c::text_update(Bit8u *old_text, Bit8u *new_text,
                                 unsigned long cursor_x, unsigned long cursor_y,
                                 bx_vga_tminfo_t *tm_info)
{

	memcpy(textBuffer, new_text, 4000);	
	isTextMode = YES;
}

void bx_nogui_gui_c::flush(void)
{
}

void bx_nogui_gui_c::clear_screen(void)
{
}

int bx_nogui_gui_c::get_clipboard_text(Bit8u **bytes, Bit32s *nbytes)
{
	return 0;
}

int bx_nogui_gui_c::set_clipboard_text(char *text_snapshot, Bit32u len)
{
	return 0;
}

bx_bool bx_nogui_gui_c::palette_change(Bit8u index, Bit8u red, Bit8u green, Bit8u blue)
{
	if (index > 255) return 0;
	
	indexed_colors[index][0] = red;
	indexed_colors[index][1] = green;
	indexed_colors[index][2] = blue;
	
	return 1;
}

void bx_nogui_gui_c::graphics_tile_update(Bit8u *tile, unsigned x0, unsigned y0)
{
	isTextMode = NO;
	int* imageData = [renderView imageData];
	
	if (currentBpp == 32) // not tested yet
	{
		for (int y = 0; y < tsy; y++)
		{
			int py = y + y0;
			memcpy(&imageData[x0 + py*currentResX], &tile[y*tsx*4], tsy * 4);
		}
	}else if (currentBpp == 16)
	{
		for (int y = 0; y < tsy; y++)
		{
			int py = y + y0;
			py = MIN(py, currentResY-1);
			
			for (int x = 0; x < tsx; x++)
			{
				int px = x + x0;
				px = MIN(px, currentResX-1);
				
				unsigned int c = ((unsigned int*)tile)[x + y*tsx];
				
				c = ((c & 0xff) << 16) | (c & 0xff00) | ((c & 0xff0000) >> 16);
				
				imageData[px + py*currentResX] = c;
			}
		}
	}else // 8
	{
		for (int y = 0; y < tsy; y++)
		{
			int py = y + y0;
			py = MIN(py, currentResY-1);
			
			for (int x = 0; x < tsx; x++)
			{
				int px = x + x0;
				px = MIN(px, currentResX-1);
				
				unsigned int c = tile[x + y*tsx];
				c = indexed_colors[c][0] | (indexed_colors[c][1] << 8) | (indexed_colors[c][2] << 16);
				imageData[px + py*currentResX] = c;
			}
		}
	}
}

void bx_nogui_gui_c::dimension_update(unsigned x, unsigned y, unsigned fheight, unsigned fwidth, unsigned bpp)
{
	currentResX = x;
	currentResX = y;
	currentBpp = bpp;
	
	if (bpp >= 8)
	{
		[renderView recreateImageContextWithX:x y:y bpp:bpp];
	}
}

void bx_nogui_gui_c::show_ips(Bit32u ips_count)
{
}

//void bx_nogui_gui_c::statusbar_setitem(int element, bx_bool active)
//{
//}

unsigned bx_nogui_gui_c::create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim)
{
	return 0;
}

unsigned bx_nogui_gui_c::headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void))
{
	return 0;
}

void bx_nogui_gui_c::show_headerbar(void)
{
}

void bx_nogui_gui_c::replace_bitmap(unsigned hbar_id, unsigned bmap_id)
{
}

void bx_nogui_gui_c::exit(void)
{
}

void bx_nogui_gui_c::mouse_enabled_changed_specific (bx_bool val)
{
}

#endif /* if BX_WITH_NOGUI */
