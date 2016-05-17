//
//  PullDownCollectionViewController.m
//  PullDownSearch
//
//  Created by Brennan Stehling on 5/13/16.
//  Copyright © 2016 Acme. All rights reserved.
//

#import "PullDownCollectionViewController.h"

static CGFloat SearchViewHeight = 50.0;
static NSInteger BoxSectionCount = 5;
static NSInteger BoxCount = 20;

@class SearchView;

#pragma mark -

@protocol SearchViewDelegate <NSObject>

- (void)searchView:(SearchView *)searchView didChangeText:(NSString *)text;
- (void)searchViewDidBecomeActive:(SearchView *)searchView;
- (void)searchViewDidBecomeInactive:(SearchView *)searchView;

@end

@interface SearchView : UICollectionReusableView <UITextFieldDelegate>

@property (weak, nonatomic) id<SearchViewDelegate> delegate;

@property (readonly, nonatomic) NSString *searchText;
@property (assign, nonatomic, getter=isActive) BOOL active;

- (void)takeFocus;

@end

@interface SearchView ()

@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) UITapGestureRecognizer *tapGesture;

@end

#pragma mark -

@implementation SearchView

- (void)awakeFromNib {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToSearch:)];
    tapGesture.delaysTouchesBegan = YES;
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    self.tapGesture = tapGesture;
}

- (void)takeFocus {
    [self.searchField becomeFirstResponder];
}

- (void)tapToSearch:(UITapGestureRecognizer *)sender {
    [self.searchField becomeFirstResponder];
    [self setActive:YES animate:YES];
}

- (NSString *)searchText {
    return self.searchField.text;
}

- (void)setActive:(BOOL)active {
    [self setActive:active animate:NO];
}

- (void)setActive:(BOOL)active animate:(BOOL)animate {
    if (_active != active) {
        _active = active;
        [self updateUI:animate];
    }
}

- (void)updateUI:(BOOL)animated {
    self.tapGesture.enabled = !self.isActive;
    if (self.active) {
        if ([self.delegate respondsToSelector:@selector(searchViewDidBecomeActive:)]) {
            [self.delegate searchViewDidBecomeActive:self];
        }
    }
    else {
        if ([self.delegate respondsToSelector:@selector(searchViewDidBecomeInactive:)]) {
            [self.delegate searchViewDidBecomeInactive:self];
        }
    }
}

- (IBAction)textEditingChanged:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchView:didChangeText:)]) {
        [self.delegate searchView:self didChangeText:self.searchField.text];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.active = YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self setActive:NO animate:YES];
    return YES;
}

@end

#pragma mark -

static NSString * const BoxCellIdentifier = @"BoxCell";

@interface BoxCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *boxView;

@end

@implementation BoxCell

@end

#pragma mark -

@interface PullDownCollectionViewController () <SearchViewDelegate>

@property (weak, nonatomic) SearchView *searchView;

@property (readonly) NSInteger sectionCount;
@property (readonly) NSInteger lastSectionIndex;

@end

typedef NS_ENUM(NSUInteger, CollectionCellType) {
    CollectionCellTypeNone     = 0,
    CollectionCellTypeSearch   = 1,
    CollectionCellTypeBox      = 2,
    CollectionCellTypeFooter   = 3
};

static const NSInteger SearchResultsSectionIndex = 1;

@implementation PullDownCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.contentOffset = CGPointMake(0.0, SearchViewHeight);
}

- (void)refresh {
    NSLog(@"Reloading Data");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refresh) object:nil];

    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:SearchResultsSectionIndex];
    [self.collectionView reloadSections:indexSet];
}

- (NSInteger)sectionCount {
    if (self.searchView.isActive) {
        // Sections: search field, search results, footer
        return 3;
    }
    else {
        return BoxSectionCount + 2; // add search and footer sections
    }
}

- (NSInteger)lastSectionIndex {
    return self.sectionCount - 1;
}

- (CollectionCellType)cellTypeForSection:(NSInteger)section {
    if (section == 0) {
        return CollectionCellTypeSearch;
    }
    else if (section == self.lastSectionIndex) {
        return CollectionCellTypeFooter;
    }
    else {
        return CollectionCellTypeBox;
    }
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.sectionCount;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    CollectionCellType cellType = [self cellTypeForSection:section];
    switch (cellType) {
        case CollectionCellTypeSearch:
            return 0;
            break;
        case CollectionCellTypeBox:
            return self.searchView.isActive ? self.searchView.searchText.length : BoxCount;
            break;
        case CollectionCellTypeFooter:
            return 0;
            break;

        default:
            NSAssert(NO, @"All cell types should return a value.");
            break;
    }

    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BoxCell *boxCell = [collectionView dequeueReusableCellWithReuseIdentifier:BoxCellIdentifier forIndexPath:indexPath];
    boxCell.boxView.backgroundColor = indexPath.item % 2 == 0 ? [UIColor lightGrayColor] : [UIColor blueColor];
    return boxCell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseIdentifier = kind == UICollectionElementKindSectionHeader ? @"SearchView" : @"FooterView";
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

    if ([view isKindOfClass:[SearchView class]]) {
        SearchView *searchView = (SearchView *)view;
        searchView.delegate = self;
        self.searchView = searchView;
    }

    return view;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    CollectionCellType cellType = [self cellTypeForSection:indexPath.section];
    if (cellType == CollectionCellTypeSearch || cellType == CollectionCellTypeFooter) {
        return CGSizeMake(width, 2.0);
    }

    CGFloat length = width / 5;
    return CGSizeMake(length, length);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    // Note: The header section will include the search field
    if (section > 0) {
        return CGSizeZero;
    }
    return CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 50.0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section < self.lastSectionIndex) {
        return CGSizeZero;
    }
    return CGSizeMake(self.collectionView.bounds.size.width, 60);
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Selected: %ld, %ld", (long)indexPath.section, (long)indexPath.item);
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - SearchViewDelegate

- (void)searchView:(SearchView *)searchView didChangeText:(NSString *)text {
    NSLog(@"Search: %@", text);
    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.25];
}

- (void)searchViewDidBecomeActive:(SearchView *)searchView {
    NSLog(@"Search: Active");
    // reloading is necessary to set alternate section structure
    [self.collectionView reloadData];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.searchView takeFocus];
    });
}

- (void)searchViewDidBecomeInactive:(SearchView *)searchView {
    NSLog(@"Search: Inactive");
    [self.collectionView reloadData];
}

@end
