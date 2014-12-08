//
//  PNBarChart.m
//  PNChartDemo
//
//  Created by kevin on 11/7/13.
//  Copyright (c) 2013年 kevinzhow. All rights reserved.
//

#import "PNBarChart.h"
#import "PNColor.h"
#import "PNChartLabel.h"
#import "PNBar.h"

@interface PNBarChart() {
    NSMutableArray* _bars;
    NSMutableArray* _labels;
}

- (UIColor *)barColorAtIndex:(NSUInteger)index;
@end

@implementation PNBarChart

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds   = YES;
        _showLabel           = YES;
        _barBackgroundColor  = PNLightGrey;
        _labels              = [NSMutableArray array];
        _bars                = [NSMutableArray array];
        _barWidthFactor      = 0.5f;
        _stackedYColors      = @[PNYellow];
    }

    return self;
}

-(void)setYValues:(NSArray *)yValues
{
    _yValues = yValues;
    [self setYLabels:yValues];

    _xLabelWidth = (self.frame.size.width - chartMargin*2)/[_yValues count];
}

-(void)setStackedYValues:(NSArray *)stackedYValues
{
    for (NSArray *stackedValues in stackedYValues) {
        if ([stackedValues count] != [self.yValues count]) {
            NSLog(@"PNChart ERROR: Stacked Y value array count does not equal yValues count. "
                  @"Ensure that yValues is set before stackedYValues.");
            
        }
    }

    _stackedYValues = stackedYValues;

    __block NSInteger max = 0;
    for (NSInteger i = 0; i < [_yValues count]; i++) {
        NSInteger totalAtIndex = [[self.yValues objectAtIndex:i] integerValue];
        for (NSArray *stackedValues in stackedYValues) {
            NSInteger value = [stackedValues[i] integerValue];
            totalAtIndex += value;
        }

        if (totalAtIndex > max) {
            max = totalAtIndex;
        }
    }

    _yValueMax = (int)max;
}

-(void)setYLabels:(NSArray *)yLabels
{
    NSInteger max = 0;
    for (NSString * valueString in yLabels) {
        NSInteger value = [valueString integerValue];
        if (value > max) {
            max = value;
        }

    }

    //Min value for Y label
    if (max < 5) {
        max = 5;
    }

    _yValueMax = (int)max;
}

-(void)setXLabels:(NSArray *)xLabels
{
    [self viewCleanupForCollection:_labels];
    _xLabels = xLabels;

    if (_showLabel) {
        _xLabelWidth = (self.frame.size.width - chartMargin*2)/[xLabels count];

        for(int index = 0; index < xLabels.count; index++)
        {
            NSString* labelText = xLabels[index];
            PNChartLabel * label = [[PNChartLabel alloc] initWithFrame:CGRectMake((index *  _xLabelWidth + chartMargin), self.frame.size.height - 30.0, _xLabelWidth, 20.0)];
            [label setTextAlignment:NSTextAlignmentCenter];
            label.text = labelText;
            [_labels addObject:label];
            [self addSubview:label];
        }
    }
}

-(void)setStrokeColor:(UIColor *)strokeColor
{
	_strokeColor = strokeColor;
}

-(void)setBarWidthFactor:(CGFloat)barWidthFactor
{
    if (barWidthFactor > 0.f && barWidthFactor <= 1.f) {
        _barWidthFactor = barWidthFactor;
    }
}

-(void)strokeChart
{
    [self viewCleanupForCollection:_bars];
    CGFloat chartCavanHeight = self.frame.size.height - chartMargin * 2 - 40.0;
    CGFloat barGap = (1 - self.barWidthFactor) / 2.f;
    NSInteger index = 0;

    for (NSString * valueString in _yValues) {
        float value = [valueString floatValue];

        float grade = (float)value / (float)_yValueMax;
        PNBar * bar;
        if (_showLabel) {
            bar = [[PNBar alloc] initWithFrame:CGRectMake((index *  _xLabelWidth + chartMargin + _xLabelWidth * barGap), self.frame.size.height - chartCavanHeight - 30.0, _xLabelWidth * _barWidthFactor, chartCavanHeight)];
        }else{
            bar = [[PNBar alloc] initWithFrame:CGRectMake((index *  _xLabelWidth + chartMargin + _xLabelWidth * barGap), self.frame.size.height - chartCavanHeight , _xLabelWidth * _barWidthFactor, chartCavanHeight)];
        }

        bar.backgroundColor = _barBackgroundColor;
        bar.barColor = [self barColorAtIndex:index];
        bar.grade = grade;
        bar.tag = index;
        [_bars addObject:bar];
        [self addSubview:bar];

        // If there's stacked Y values, we need to build that too.
        if (self.stackedYValues) {
            __block float currentGrade = grade;
            for (__block int stackIndex = 0; stackIndex < [self.stackedYValues count]; stackIndex++) {
                float stackedValue = [self.stackedYValues[stackIndex][index] floatValue];
                float stackedGrade = stackedValue / (float)_yValueMax;

                PNBar *stackedBar = [[PNBar alloc]
                              initWithFrame:CGRectMake(bar.frame.origin.x,
                                                       bar.frame.origin.y - (chartCavanHeight * currentGrade) - 0.5f,
                                                       bar.frame.size.width,
                                                       chartCavanHeight - (0.5f * (stackIndex + 1)))];
                stackedBar.layer.cornerRadius = 0.f;
                stackedBar.backgroundColor = [UIColor clearColor];
                stackedBar.barColor = self.stackedYColors[stackIndex];//_stackedYColor;
                stackedBar.tag = -index - 1;
                // Queue setting grade after 1.0 second per stack index (hardcoded animation value).
                // This strokes the stacked part of the bars after the main part.
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1.0 * (stackIndex + 1) * NSEC_PER_SEC)));
                dispatch_after(time, dispatch_get_main_queue(), ^{
                    stackedBar.grade = stackedGrade;
                });
                currentGrade += stackedGrade;

                [_bars addObject:stackedBar];
                [self addSubview:stackedBar];
            }
        }

        index += 1;
    }
}

- (void)viewCleanupForCollection:(NSMutableArray*)array
{
    if (array.count) {
        [array makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [array removeAllObjects];
    }
}

#pragma mark - Class extension methods

- (UIColor *)barColorAtIndex:(NSUInteger)index
{
    if ([self.strokeColors count] == [self.yValues count]) {
        return self.strokeColors[index];
    } else {
        return self.strokeColor;
    }
}

#pragma mark - Touch detection

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchPoint:touches withEvent:event];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchPoint:(NSSet *)touches withEvent:(UIEvent *)event
{
    //Get the point user touched
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    UIView *subview = [self hitTest:touchPoint withEvent:nil];

    if ([subview isKindOfClass:[PNBar class]] && [self.delegate respondsToSelector:@selector(userClickedOnBarChartIndex:bar:)]) {
        [self.delegate userClickedOnBarChartIndex:subview.tag bar:(PNBar *)subview];
    }
}

@end
