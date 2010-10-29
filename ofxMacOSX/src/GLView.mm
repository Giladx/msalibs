
#import "GLView.h"
#import <OpenGL/gl.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import "ofxCocoa.h"


@implementation GLView


-(NSOpenGLContext*)openGLContext {
	return openGLContext;
}

-(NSOpenGLPixelFormat*)pixelFormat {
	return pixelFormat;
}

//------ DISPLAY LINK STUFF ------
-(CVReturn)getFrameForTime:(const CVTimeStamp*)outputTime {
	[self updateAndDraw];
	
    return kCVReturnSuccess;
}


// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext){
    CVReturn result = [(GLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

-(void)setupDisplayLink {
	NSLog(@"glView::setupDisplayLink");
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
	
	// Set the display link for the current renderer
	CGLContextObj cglContext = (CGLContextObj)[[self openGLContext] CGLContextObj];
	CGLPixelFormatObj cglPixelFormat = (CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj];
	CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
	
	// start it
	CVDisplayLinkStart(displayLink);
}

-(void)releaseDisplayLink {
	NSLog(@"glView::releaseDisplayLink");
	
	CVDisplayLinkStop(displayLink);
	CVDisplayLinkRelease(displayLink);
	displayLink = 0;
}

// --------------------------------

-(void)setupTimer {
	NSLog(@"glView::setupTimer");
//	if(targetFrameRate){

//	timer = [[NSTimer scheduledTimerWithTimeInterval:(1.0f / targetFrameRate) target:self selector:@selector(updateAndDraw) userInfo:nil repeats:YES] retain];
	timer = [[NSTimer timerWithTimeInterval:(1.0f / targetFrameRate) target:self selector:@selector(updateAndDraw) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
}

-(void)releaseTimer {
	NSLog(@"glView::releaseTimer");
	
	[timer invalidate];
	timer = 0;
}

// --------------------------------

-(void)startAnimation {
	NSLog(@"glView::startAnimation using displayLink %@", useDisplayLink ? @"YES" : @"NO");
	
	if(!isAnimating /*&& displayLink && !CVDisplayLinkIsRunning(displayLink)*/){
		isAnimating = true;
		
		if(useDisplayLink){
			[self setupDisplayLink];
		} else {
			[self setupTimer];
		}			
	}
}

-(void)stopAnimation {
	NSLog(@"glView::stopAnimation using displayLink %@", useDisplayLink ? @"YES" : @"NO");
	if(isAnimating /*&& displayLink && CVDisplayLinkIsRunning(displayLink)*/) {
		isAnimating = false;
		
		if(useDisplayLink) {
			[self releaseDisplayLink];
		} else {
			[self releaseTimer];
		}
	}
}

-(void)toggleAnimation {
	if (isAnimating) [self stopAnimation];
	else [self startAnimation];
}

-(void)setFrameRate:(float)rate {
	NSLog(@"glView::setFrameRate %f", rate);
	
	[self stopAnimation];
	
	targetFrameRate = rate;
	
	if(rate == 60) {
		useDisplayLink = true;
	} else {
		useDisplayLink = false;
	}
	
	[self startAnimation];
}


-(void)reshape {
	// This method will be called on the main thread when resizing, but we may be drawing on a secondary thread through the display link
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	
	// Delegate to the scene object to update for a change in the view size
	//	[[controller scene] setViewportRect:[self bounds]];// TODO
	[[self openGLContext] update];
	
	CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}


-(void)drawRect:(NSRect)dirtyRect {
	// Ignore if the display link is still running
//	if (!CVDisplayLinkIsRunning(displayLink))
//		[self updateAndDraw];
}


-(void)updateAndDraw {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Update the animation
	//	CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
	//	[[controller scene] advanceTimeBy:(currentTime - [controller renderTime])];
	//	[controller setRenderTime:currentTime];
	
	// This method will be called on both the main thread (through -drawRect:) and a secondary thread (through the display link rendering loop)
	// Also, when resizing the view, -reshape is called on the main thread, but we may be drawing on a secondary thread
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	
	// Make sure we draw to the right context
	[[self openGLContext] makeCurrentContext];
	
	// Delegate to the scene object for rendering
	ofxGetAppCocoaWindow()->update();
	ofxGetAppCocoaWindow()->draw();
	
	[[self openGLContext] flushBuffer];
	
	CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
	
	[pool release];
}


-(id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context {
	NSLog(@"GLView::initWithFrame %@", NSStringFromRect(frameRect));
	
	isAnimating		= false;
	useDisplayLink	= true;
	
	ofAppCocoaWindow *cocoaWindowPtr = (ofAppCocoaWindow*)ofxGetAppCocoaWindow();
	int numberOfFSAASamples = cocoaWindowPtr->numberOfFSAASamples;
	
	pixelFormat = nil;
	
	
	/* Choose a pixel format */
	if(numberOfFSAASamples) {
		NSOpenGLPixelFormatAttribute attribs[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAMultiScreen,
			NSOpenGLPFADepthSize, 24,
			NSOpenGLPFAAlphaSize, 8,
			NSOpenGLPFAColorSize, 32,
			NSOpenGLPFASampleBuffers, 1,
			NSOpenGLPFASamples, numberOfFSAASamples,
			NSOpenGLPFANoRecovery,
		0};
		
		NSLog(@"   trying Multisampling");
		pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
		if(pixelFormat) {
			NSLog(@"      Multisampling supported");
			glEnable(GL_MULTISAMPLE);
		} else {
			NSLog(@"      Multisampling not supported");
		}
	}
	
	
	if(pixelFormat == nil) {
		NSLog(@"   trying non multisampling");
		NSOpenGLPixelFormatAttribute attribs[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFADoubleBuffer,
			NSOpenGLPFAMultiScreen,
			NSOpenGLPFADepthSize, 24,
			NSOpenGLPFAAlphaSize, 8,
			NSOpenGLPFAColorSize, 32,
			NSOpenGLPFANoRecovery,
		0};		
		
		pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
		glDisable(GL_MULTISAMPLE);
		if(pixelFormat == nil) {
			NSLog(@"      not even that. fail");
		}
	} 
	
	
	openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:context];
	
	if (self = [super initWithFrame:frameRect]) {
		[[self openGLContext] makeCurrentContext];
		
		// Synchronize buffer swaps with vertical refresh rate
		GLint swapInt = 0;
		[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; 
		
		// Look for changes in view size
		// Note, -reshape will not be called automatically on size changes because NSView does not export it to override 
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(reshape) 
													 name:NSViewGlobalFrameDidChangeNotification
												   object:self];
	}
	
	return self;
}

-(id) initWithFrame:(NSRect)frameRect {
	self = [self initWithFrame:frameRect shareContext:nil];
	return self;
}
	
-(void)lockFocus {
	[super lockFocus];
	if ([[self openGLContext] view] != self)
		[[self openGLContext] setView:self];
}

-(void)dealloc {
	[self stopAnimation];
	
	[openGLContext release];
	[pixelFormat release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSViewGlobalFrameDidChangeNotification
												  object:self];
	[super dealloc];
}	



-(void)awakeFromNib {
	NSLog(@"GLView::awakeFromNib, window:%@",[self window]);
	[[self window] setAcceptsMouseMovedEvents:YES]; 
	ofxGetAppCocoaWindow()->initWindowSize();
}




-(void)goFullscreen:(int)whichScreen {
	NSLog(@"goFullscreen");
	savedWindowFrame = [[self window] frame];
	if(savedWindowFrame.size.width == 0 || savedWindowFrame.size.height == 0) {
		savedWindowFrame.size = NSMakeSize(1024, 768);
	}
	
	// need to create window from scratch, not nib
	SetSystemUIMode(kUIModeAllHidden, NULL);
	NSRect rect = NSZeroRect;

	if(whichScreen == OF_ALL_SCREENS) {
		for(NSScreen *s in [NSScreen screens]) rect = NSUnionRect(rect, s.frame);
		NSLog(@"goFullscreen: OF_ALL_SCREENS %@", NSStringFromRect(rect));

	} else {
		SetSystemUIMode(kUIModeAllHidden,NULL);
		
		NSScreen *screen;
		if(whichScreen == OF_CURRENT_SCREEN) screen = [[self window] screen];
		else screen = [[NSScreen screens] objectAtIndex:whichScreen];
		rect = screen.frame;

		NSLog(@"goFullscreen: %@", screen);
//
//		NSScreen *screen;
//		if(whichScreen == OF_CURRENT_SCREEN) screen = [[self window] screen];
//		else screen = [[NSScreen screens] objectAtIndex:whichScreen];
//		if([self respondsToSelector:@selector(isInFullScreenMode)]){
//			[self enterFullScreenMode:[[self window] screen]
//						  withOptions:[NSDictionary dictionaryWithObjectsAndKeys: 
//									   [NSNumber numberWithBool: YES], NSFullScreenModeAllScreens, 
//									   [NSNumber numberWithInt:NSNormalWindowLevel], NSFullScreenModeWindowLevel, 
//									   nil]];
//		}
	}
	
	[[self window] setFrame:rect display:YES animate:NO];
	[[self window] setLevel:NSMainMenuWindowLevel+1];
	
//		[[self window] setLevel:NSScreenSaverWindowLevel];	// FIX
//		[self setBounds:rect];
	
	ofxGetAppCocoaWindow()->windowMode = OF_FULLSCREEN;
}

-(void)goFullscreen {
	[self goFullscreen:OF_ALL_SCREENS];
}



// ---------------------------------
-(void)goWindow{
	SetSystemUIMode(kUIModeNormal, NULL);
	if(savedWindowFrame.size.width == 0 || savedWindowFrame.size.height == 0) {
		savedWindowFrame.size = NSMakeSize(1024, 768);
	}
	
	[[self window] setFrame:savedWindowFrame display:YES animate:NO];
	[[self window] setLevel:NSNormalWindowLevel];

	
//	if([self respondsToSelector:@selector(isInFullScreenMode)]){
//		if([self isInFullScreenMode]){
//			[self exitFullScreenModeWithOptions:nil];
//		}
//	}

	ofxGetAppCocoaWindow()->windowMode = OF_WINDOW;
}


//-(void)setCurrentContext {
//	[[self openGLContext] makeCurrentContext];
//}
//
//-(void)flush {
//	[[self openGLContext] flushBuffer];
//}
//
//



-(BOOL)acceptsFirstResponder {
	return YES;
}

-(BOOL)becomeFirstResponder {
	return  YES;
}

-(BOOL)resignFirstResponder {
	return YES;
}


#pragma mark Events

//TODO: dispatch this properly


-(void)keyDown:(NSEvent *)theEvent {
//	NSLog(@"keyDown");
	NSString *characters = [theEvent characters];
	if ([characters length]) {
		unichar key = [characters characterAtIndex:0];
		ofGetAppPtr()->keyPressed(key);
	}
}

-(void)keyUp:(NSEvent *)theEvent {
//	NSLog(@"keyUp");
	NSString *characters = [theEvent characters];
	if ([characters length]) {
		unichar key = [characters characterAtIndex:0];
		ofGetAppPtr()->keyReleased(key);
	}
}

// ---------------------------------

-(void)mouseDown:(NSEvent *)theEvent {
//	NSLog(@"mouseDown");
	if ([theEvent modifierFlags] & NSControlKeyMask) 
		[self rightMouseDown:theEvent];
	else if ([theEvent modifierFlags] & NSAlternateKeyMask) 
		[self otherMouseDown:theEvent];
	else {
		NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		ofGetAppPtr()->mouseX = p.x;
		ofGetAppPtr()->mouseY = self.frame.size.height-p.y;
		ofGetAppPtr()->mousePressed(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 0);
	}
}

// ---------------------------------

-(void)rightMouseDown:(NSEvent *)theEvent {
	//	NSLog(@"rightMouseDown");
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	ofGetAppPtr()->mouseX = p.x;
	ofGetAppPtr()->mouseY = self.frame.size.height-p.y;
	ofGetAppPtr()->mousePressed(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 1);
}

// ---------------------------------

-(void)otherMouseDown:(NSEvent *)theEvent {
	//	NSLog(@"otherMouseDown");
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];	
	ofGetAppPtr()->mouseX = p.x;
	ofGetAppPtr()->mouseY = self.frame.size.height-p.y;
	ofGetAppPtr()->mousePressed(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 2);
}

-(void)mouseMoved:(NSEvent *)theEvent{
	//	NSLog(@"mouseMoved");
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];	
	ofGetAppPtr()->mouseX = p.x;
	ofGetAppPtr()->mouseY = self.frame.size.height-p.y;
	ofGetAppPtr()->mouseMoved(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY);
}


// ---------------------------------

-(void)mouseUp:(NSEvent *)theEvent {
	//	NSLog(@"mouseUp");
	ofGetAppPtr()->mouseReleased(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 0);
	ofGetAppPtr()->mouseReleased();
}

// ---------------------------------

-(void)rightMouseUp:(NSEvent *)theEvent {
	//	NSLog(@"rightMouseUp");
	ofGetAppPtr()->mouseReleased(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 1);
	ofGetAppPtr()->mouseReleased();
}

// ---------------------------------

-(void)otherMouseUp:(NSEvent *)theEvent {
	//	NSLog(@"otherMouseUp");
	ofGetAppPtr()->mouseReleased(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 2);
	ofGetAppPtr()->mouseReleased();
}

// ---------------------------------

-(void)mouseDragged:(NSEvent *)theEvent {
	//	NSLog(@"mouseDragged");
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	ofGetAppPtr()->mouseX = p.x;
	ofGetAppPtr()->mouseY = self.frame.size.height-p.y;
	ofGetAppPtr()->mouseDragged(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 0);
}

// ---------------------------------

-(void)rightMouseDragged:(NSEvent *)theEvent {
	//	NSLog(@"rightMouseDragged");
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	ofGetAppPtr()->mouseX = p.x;
	ofGetAppPtr()->mouseY = self.frame.size.height-p.y;
	ofGetAppPtr()->mouseDragged(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 1);
}

// ---------------------------------

-(void)otherMouseDragged:(NSEvent *)theEvent {
	//	NSLog(@"otherMouseDragged");
	
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	ofGetAppPtr()->mouseX = p.x;
	ofGetAppPtr()->mouseY = self.frame.size.height-p.y;
	ofGetAppPtr()->mouseDragged(ofGetAppPtr()->mouseX, ofGetAppPtr()->mouseY, 2);
}

-(void)scrollWheel:(NSEvent *)theEvent {
	//	NSLog(@"scrollWheel");
	
	//	float wheelDelta = [theEvent deltaX] +[theEvent deltaY] + [theEvent deltaZ];
	//	if (wheelDelta)
	//	{
	//		GLfloat deltaAperture = wheelDelta * -camera.aperture / 200.0f;
	//
	//	}
}



@end
