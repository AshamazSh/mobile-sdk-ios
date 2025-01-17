/*   Copyright 2022 APPNEXUS INC
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import "XandrNativeAdView.h"

@implementation XandrNativeAdView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    self.viewForTracking.frame = dirtyRect;
}


-(void)attachClickableView{
    self.viewForTracking = [[NSView alloc] initWithFrame:CGRectMake(0, 0 ,1,1)];
    [self.viewForTracking setWantsLayer:YES];
    self.viewForTracking.layer.backgroundColor = [[NSColor clearColor] CGColor];
    [self addSubview:self.viewForTracking positioned:NSWindowAbove relativeTo:nil];
}

-(void)detachClickableView{
    [self.viewForTracking removeFromSuperview];
}
@end
