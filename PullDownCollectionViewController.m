//
//  PullDownCollectionViewController.m
//  PullDownSearch
//
//  Created by Brennan Stehling on 5/13/16.
//  Copyright © 2016 Acme. All rights reserved.
//

#import "PullDownCollectionViewController.h"

static CGFloat SearchViewHeight = 50.0;
static NSUInteger BoxCount = 10;

@class SearchView;

#pragma mark -

@protocol SearchViewDelegate <NSObject>

- (void)searchView:(SearchView *)searchView didChangeText:(NSString *)text;

@end

@interface SearchView : UICollectionReusableView <UITextFieldDelegate>

@property (weak, nonatomic) id<SearchViewDelegate> delegate;

@property (assign, nonatomic, getter=isActive) BOOL active;

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

- (void)tapToSearch:(UITapGestureRecognizer *)sender {
    [self.searchField becomeFirstResponder];
    [self setActive:YES animate:YES];
}

- (void)setActive:(BOOL)active animate:(BOOL)animate {
    if (_active != active) {
        _active = active;
        [self updateUI:animate];
    }
}

- (void)updateUI:(BOOL)animated {
    self.tapGesture.enabled = !self.isActive;
}

- (IBAction)textEditingChanged:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(searchView:didChangeText:)]) {
        [self.delegate searchView:self didChangeText:self.searchField.text];
    }
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (self.isActive) {
        [self.searchField becomeFirstResponder];
    }
}

- (void)prepareForReuse {
    [self setNeedsDisplay];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.active = true;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self setActive:NO animate:YES];
    return YES;
}

@end

#pragma mark -

@interface BoxCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *boxView;

@end

@implementation BoxCell
@end

#pragma mark -

@interface PullDownCollectionViewController () <SearchViewDelegate>

@property (weak, nonatomic) SearchView *searchView;

@end

@implementation PullDownCollectionViewController

static NSString * const reuseIdentifier = @"BoxCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.collectionView.contentOffset = CGPointMake(0.0, SearchViewHeight);
}

- (void)refresh {
    NSLog(@"Reloading Data");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refresh) object:nil];
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return BoxCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    BoxCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BoxCell" forIndexPath:indexPath];
    cell.boxView.backgroundColor = indexPath.item % 2 == 0 ? [UIColor lightGrayColor] : [UIColor blueColor];
    return cell;
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
    CGFloat length = width / 5;
    if (indexPath.item != 0 && indexPath.item % 11 ==0) {
        return CGSizeMake(width, length);
    }
    else {
        return CGSizeMake(length, length);
    }
}

#pragma mark - UICollectionViewDelegate

// nothing to do

#pragma mark - SearchViewDelegate

- (void)searchView:(SearchView *)searchView didChangeText:(NSString *)text {
    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.25];
}

@end