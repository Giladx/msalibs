/***********************************************************************
 
 Copyright (c) 2008, 2009, 2010 Memo Akten, www.memo.tv
 *** The Mega Super Awesome Visuals Company ***
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of MSA Visuals nor the names of its contributors
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***********************************************************************/

#pragma once

#include "ofMain.h"
#include "ofxVectorMath.h"
#include "MSAColor.h"

namespace MSA {
	
#define MSA_HOST_SUFFIX		"-OF"
	
#if defined (TARGET_OSX)
#define MSA_TARGET_OSX
	
#elif defined (TARGET_LINUX)
#define MSA_TARGET_LINUX

#elif defined (TARGET_WIN32)
#define MSA_TARGET_WIN32

#elif defined (TARGET_IPHONE)
#define MSA_TARGET_IPHONE)
#endif
	
#if defined (TARGET_OPENGLES)
#define MSA_TARGET_OPENGLES
#endif
	
	typedef ofxVec2f	Vec2f;
	typedef ofxVec3f	Vec3f;
	typedef ofxVec4f	Vec4f;
//	typedef Color		Color;
	
	inline string dataPath(string path, bool absolute = false)		{	return ofToDataPath(path, absolute);	}
	
	inline double getElapsedSeconds()								{	return ofGetElapsedTimef(); }
	
	inline float rand(float f)										{	return ofRandom(0, f);	}
	inline float rand(float a, float b)								{	return ofRandom(a, b);	}
	inline float randFloat()										{	return ofRandomf(); }
	
	inline void drawBitmapString(string s, float x, float y)		{	ofDrawBitmapString(s, x, y); }
}