#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CaptainHook/CaptainHook.h>

@interface UITableViewIndex : UIControl {
@private
	NSArray *_titles;
	UIFont *_font;
	NSInteger _selectedSection;
	BOOL _pastTop;
	BOOL _pastBottom;
	CGSize _cachedSize;
	CGSize _cachedSizeToFit;
	UIColor *_indexColor;
	UIColor *_indexBackgroundColor;
}
@property (readonly, assign, nonatomic) NSInteger selectedSection;
@property (readonly, assign, nonatomic) BOOL pastTop;
@property (readonly, assign, nonatomic) BOOL pastBottom;
@property (readonly, assign, nonatomic) NSString *selectedSectionTitle;
@property (retain, nonatomic) UIColor *indexBackgroundColor;
@property (retain, nonatomic) UIColor *indexColor;
@property (retain, nonatomic) UIFont *font;
@property (retain, nonatomic) NSArray *titles;
- (id)initWithFrame:(CGRect)frame;
- (void)dealloc;
- (CGSize)sizeThatFits:(CGSize)size;
- (NSInteger)maximumNumberOfTitlesWithoutTruncationForHeight:(CGRect)height;
- (void)drawRect:(CGRect)rect;
- (void)_selectSectionForTouch:(UITouch *)touch withEvent:(UIEvent *)event;
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
- (void)cancelTrackingWithEvent:(UIEvent *)event;
@end


#define kTitleCount 300
static NSArray *indexTitles;

%hook UITableView

- (void)_updateIndex
{
	id *dataSource = CHIvarRef(self, _dataSource, id);
	if (dataSource) {
		id oldDataSource = *dataSource;
		*dataSource = self;
		%orig;
		*dataSource = oldDataSource;
	} else {
		%orig;
	}
}

- (void)_sectionIndexChanged:(UITableViewIndex *)sender
{
	CGPoint offset;
	offset.x = self.contentOffset.x;
	if (sender.pastTop)
		offset.y = 0.0f;
	else {
		CGFloat tableHeight = self.bounds.size.height;
		CGFloat contentHeight = self.contentSize.height;
		if (sender.pastBottom)
			offset.y = contentHeight - tableHeight;
		else
			offset.y = (contentHeight - tableHeight) * sender.selectedSection / kTitleCount;
	}
	self.contentOffset = offset;
}

- (void)layoutSubviews
{
	%orig;
	if ([self.dataSource sectionIndexTitlesForTableView:self] == indexTitles) {
		CGFloat tableHeight = self.bounds.size.height;
		CGFloat contentHeight = self.contentSize.height;
		CHIvar(self, _index, UIView *).alpha = tableHeight < contentHeight ? 0.25f : 0.0f;
	}
}

%end

@implementation NSObject (SliderBarLoopBack)

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return indexTitles;
}

@end


%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray *array = [[NSMutableArray alloc] init];
	for (int i = 0; i < kTitleCount; i++)
		[array addObject:@" "];
	indexTitles = array;
	[pool drain];
}
