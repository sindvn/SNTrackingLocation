//
//  UIBezierPath+GuidedPath.m
//  Pods
//
//  Created by Ivan Li on 16/6/2016.
//
//

#import "UIBezierPath+GuidedPath.h"

#define TYPE(_ARR_) (((NSNumber*)_ARR_[0]).integerValue)
#define P0(_ARR_) [((NSValue*)_ARR_[1]) CGPointValue]
#define P1(_ARR_) [((NSValue*)_ARR_[2]) CGPointValue]
#define P2(_ARR_) [((NSValue*)_ARR_[3]) CGPointValue]
#define VALUE(_PT_) [NSValue valueWithCGPoint:_PT_]
#define POINT(_VAL_) [_VAL_ CGPointValue]
#define MIDPOINT(a,b) CGPointMake((a.x+b.x)/2,(a.y+b.y)/2)
#define SUB(a,b) CGPointMake((a.x-b.x),(a.y-b.y))
#define SUM(a,b) CGPointMake((a.x+b.x),(a.y+b.y))
#define SCALE(a,v) CGPointMake(a.x/v,a.y/v)

@implementation UIBezierPath (GuidedPath)

float distance(NSArray *bezPt1, NSArray *bezPt2) {
    CGPoint p1 = P0(bezPt1);
    CGPoint p2 = P0(bezPt2);
    
    CGFloat xDist = (p2.x - p1.x);
    CGFloat yDist = (p2.y - p1.y);
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    return distance;
}

void getBezierElements(void *outArray, const CGPathElement *element)
{
    NSMutableArray *bezierElements = (__bridge NSMutableArray *)outArray;
    CGPathElementType type = element->type;
    CGPoint *points = element->points;
    
    switch (type)
    {
        case kCGPathElementCloseSubpath:
            [bezierElements addObject:@[@(type)]];
            break;
        case kCGPathElementMoveToPoint:
        case kCGPathElementAddLineToPoint:
            [bezierElements addObject:@[@(type), VALUE(points[0])]];
            break;
        case kCGPathElementAddQuadCurveToPoint:
            [bezierElements addObject:@[@(type), VALUE(points[1]), VALUE(points[0])]];
            break;
        case kCGPathElementAddCurveToPoint:
            [bezierElements addObject:@[@(type), VALUE(points[2]), VALUE(points[0]), VALUE(points[1])]];//dest, cp1, cp2
            break;
    }
}

UIBezierPath *bezierFromElements(NSArray * elements)
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [elements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *element = (NSArray*) obj;
        switch(TYPE(element)) {
            case kCGPathElementCloseSubpath:
                [path closePath];
                break;
            case kCGPathElementMoveToPoint:
                [path moveToPoint:P0(element)];
            case kCGPathElementAddLineToPoint:
                [path addLineToPoint:P0(element)];
                break;
            case kCGPathElementAddQuadCurveToPoint:
                [path addQuadCurveToPoint:P0(element) controlPoint:P1(element)];
                break;
            case kCGPathElementAddCurveToPoint:
                [path addCurveToPoint:P0(element) controlPoint1:P1(element) controlPoint2:P2(element)];
                break;
        }
    }];
    return path;
}
UIBezierPath *bezierFlatFromElements(NSArray *elements)
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [elements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *element = (NSArray*) obj;
        switch(TYPE(element)) {
            case kCGPathElementCloseSubpath:
                [path closePath];
                break;
            case kCGPathElementMoveToPoint:
                [path moveToPoint:P0(element)];
                break;
            case kCGPathElementAddLineToPoint:
            case kCGPathElementAddCurveToPoint:
            case kCGPathElementAddQuadCurveToPoint:
                [path addLineToPoint:P0(element)];
                break;
        }
    }];
    return path;
    
}


NSArray *cardinal(NSArray *elements, float tension)
{
    if(elements.count<2) return elements;
    
    NSMutableArray *derivatives = [[NSMutableArray alloc] init];
    
    for(NSInteger j=0;j<elements.count;j++) {
        CGPoint prev = P0(elements[MAX(j-1,0)]);
        CGPoint next = P0(elements[MIN(j+1,elements.count-1)]);
        
        [derivatives addObject:@[ @(kCGPathElementMoveToPoint) , VALUE(SCALE(SUB(next,prev),tension)) ]];
    }
    
    NSMutableArray *card = [[NSMutableArray alloc] init];
    
    for(NSUInteger i=0;i<elements.count;i++) {
        if(i==0) {
            [card addObject: elements[0] ];
        } else {
            CGPoint d = P0(elements[i]);
            CGPoint cp1 = SUM( P0(elements[i-1]) , SCALE(P0(derivatives[i-1]),tension) );
            CGPoint cp2 = SUB( P0(elements[i]), SCALE( P0(derivatives[i]),tension) );
            
            if (cp1.x < 0 || cp1.y < 0 ||cp2.x < 0 || cp2.y < 0
                || angleBetweenMinAndMax(getAngle(cp1,d,cp2), 0, 5)
                || angleBetweenMinAndMax(getAngle(d,cp1,cp2), 0, 5)
                || angleBetweenMinAndMax(getAngle(d,cp2,cp1), 0, 5)
                )
            { // if cp point position is negative we draw line
                [card addObject:@[ @(kCGPathElementAddLineToPoint) , VALUE(d)]];
            }
            else {
                [card addObject:@[ @(kCGPathElementAddCurveToPoint) , VALUE(d), VALUE(cp1), VALUE(cp2) ]];
            }
        }
    }
    return card;
}

bool angleBetweenMinAndMax(int value, int min, int max)
{
    return (value >= min) && (value <= max);
}

int getAngle( CGPoint a, CGPoint b, CGPoint c )
{
    CGPoint ab = CGPointMake(b.x - a.x,  b.y - a.y);
    CGPoint cb = CGPointMake( b.x - c.x,  b.y - c.y);
    
    float dot = (ab.x * cb.x + ab.y * cb.y); // dot product
    float cross = (ab.x * cb.y - ab.y * cb.x); // cross product
    
    float alpha = atan2(cross, dot);
    
    return  floor(alpha * 180. / 3.1415 + 0.5);
}

-(UIBezierPath*) bezierCardinalWithTension:(CGFloat) tension {
    tension = MAX(MIN(tension,4.0),0.0);
    NSMutableArray *elements = [NSMutableArray array];
    CGPathApply(self.CGPath, (__bridge void*)elements, getBezierElements);
    
    NSArray *flattenedElements = cardinal(elements,tension);
    
    return  bezierFromElements(flattenedElements);
}

-(UIBezierPath*)bezierFlat {
    NSMutableArray *elements = [NSMutableArray array];
    CGPathApply(self.CGPath, (__bridge void*)elements, getBezierElements);
    
    return bezierFlatFromElements(elements);
}

@end
