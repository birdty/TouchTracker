//
//  BNRDrawView.m
//  TouchTracker
//
//  Created by Tyler Bird on 2/20/16.
//  Copyright (c) 2016 Big Nerd Ranch. All rights reserved.
//

#import "BNRDrawView.h"
#import "BNRLine.h"

@interface BNRDrawView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableDictionary * linesInProgress;
@property (nonatomic, strong) NSMutableArray * finishedLines;
@property (nonatomic, weak) BNRLine * selectedLine;
@property (nonatomic, strong) UIPanGestureRecognizer * moveRecognizer;

@end

@implementation BNRDrawView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if ( self )
    {
        self.linesInProgress = [[NSMutableDictionary alloc] init];
        self.finishedLines = [[NSMutableArray alloc] init];
        self.backgroundColor = [UIColor grayColor];
        self.multipleTouchEnabled = YES;
        
        UITapGestureRecognizer * doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        
        doubleTapRecognizer.numberOfTapsRequired = 2;
        doubleTapRecognizer.delaysTouchesBegan = YES;
        
        UITapGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        
        tapRecognizer.delaysTouchesBegan = NO;
        
        [self addGestureRecognizer:tapRecognizer];
        
        UILongPressGestureRecognizer * pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        
        [self addGestureRecognizer:pressRecognizer];
        
        self.moveRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveLine:)];
        
        self.moveRecognizer.delegate = self;
        
        self.moveRecognizer.cancelsTouchesInView = NO;
        
       [self addGestureRecognizer:self.moveRecognizer];

        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        
        [self addGestureRecognizer:doubleTapRecognizer];
        
    }
    
    return self;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ( gestureRecognizer == self.moveRecognizer )
    {
        return  YES;
    }
    
    return  NO;
}

-(void)moveLine:(UIPanGestureRecognizer *)gr
{
    if ( ! self.selectedLine )
    {
        return;
    }
 
    if ( gr.state == UIGestureRecognizerStateBegan )
    {
        gr.cancelsTouchesInView = YES;
    }
    else if ( gr.state == UIGestureRecognizerStateChanged )
    {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        
        CGPoint translation = [gr translationInView:self];
        
        CGPoint begin = self.selectedLine.begin;
        CGPoint end = self.selectedLine.end;
        
        begin.x += translation.x;
        begin.y += translation.y;
        
        end.x += translation.x;
        end.y += translation.y;
        
        self.selectedLine.begin = begin;
        self.selectedLine.end = end;
    
        [self setNeedsDisplay];
        
        [gr setTranslation:CGPointZero inView:self];
    }
    else if ( gr.state == UIGestureRecognizerStateEnded )
    {
        NSLog(@"executed pan recognizer end..");
        gr.cancelsTouchesInView = NO;
        gr.enabled = NO;
        [self setNeedsDisplay];
    }
}

-(void)tap:(UIGestureRecognizer *)gr
{
    CGPoint point = [gr locationInView:self];
    
    self.selectedLine = [self lineAtPoint:point];
    
    if ( self.selectedLine )
    {
        [self becomeFirstResponder];
        
        UIMenuController * menu = [UIMenuController sharedMenuController];
        
        UIMenuItem * deleteItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteLine:)];
        
        menu.menuItems = @[deleteItem];
        
        [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        
        [menu setMenuVisible:YES animated:YES];
    }
    else
    {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        self.selectedLine = nil;
    }
    
    [self setNeedsDisplay];
}

-(void)deleteLine:(id)sender
{
    [self.finishedLines removeObject:self.selectedLine];
    
    [self setNeedsDisplay];
}

-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)doubleTap:(UIGestureRecognizer *)gr
{
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

-(void)strokeLine:(BNRLine *)line
{
    UIBezierPath * bp = [UIBezierPath bezierPath];
    
    bp.lineWidth = 10;
    
    bp.lineCapStyle = kCGLineCapRound;
    
    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    
    [bp stroke];
}


-(void)drawRect:(CGRect)rect
{
    [[UIColor blackColor] set];
    
    for( BNRLine * line in self.finishedLines )
    {
        [self strokeLine:line];
    }

    [[UIColor redColor] set];
    
    for( NSValue * key in self.linesInProgress )
    {
        [self strokeLine:self.linesInProgress[key]];
    }
    
    if ( self.selectedLine )
    {
        [[UIColor greenColor] set];
        [self strokeLine:self.selectedLine];
    }
}

-(BNRLine *)lineAtPoint:(CGPoint)p
{
    for (BNRLine * l in self.finishedLines )
    {
        CGPoint start = l.begin;
        CGPoint end = l.end;
        
        for(float t = 0.0; t <= 1.0; t += 0.05 )
        {
            float x = start.x + t * ( end.x - start.x );
            float y = start.y + t * ( end.y - start.y );
            
            if ( hypot(x - p.x, y - p.y) < 20.0 )
            {
                return l;
            }
        }
    }
    
    return  nil;
}

-(void)longPress:(UIGestureRecognizer *)gr
{
    
}

-(BOOL)selectedLineAtPoint:(CGPoint)p
{
    if ( self.selectedLine )
    {
        BNRLine * l = self.selectedLine;
        
        CGPoint start = l.begin;
        CGPoint end = l.end;
            
        for(float t = 0.0; t <= 1.0; t += 0.05 )
        {
            float x = start.x + t * ( end.x - start.x );
            float y = start.y + t * ( end.y - start.y );
            
            if ( hypot(x - p.x, y - p.y) < 20.0 )
            {
                return YES;
            }
        }
    }

    return NO;
}


#pragma mark - touch handlers

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.moveRecognizer.cancelsTouchesInView = NO;
    self.moveRecognizer.enabled = YES;
    
    // deselect selected line if it exists.
    
    for(UITouch * t in touches )
    {
        CGPoint point = [t locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
    }
    
    for ( UITouch * t in touches )
    {
        CGPoint location = [t locationInView:self];
        
        BNRLine * line = [[BNRLine alloc] init];
        line.begin = location;
        line.end = location;
        
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        
        self.linesInProgress[key] = line;
    }
    
    [self setNeedsDisplay];
        
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch * t in touches )
    {
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        
        BNRLine * line = self.linesInProgress[key];
        
        line.end = [t locationInView:self];
    }
    
    [self setNeedsDisplay];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch * t in touches )
    {
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        
        BNRLine * line = self.linesInProgress[key];
        
        [self.finishedLines addObject:line];
        
        [self.linesInProgress removeObjectForKey:key];
        
    }
    
    [self setNeedsDisplay];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch * t in touches )
    {
        NSValue * key = [NSValue valueWithNonretainedObject:t];
        [self.linesInProgress removeObjectForKey:key];
    }
    
    [self setNeedsDisplay];
}


@end
