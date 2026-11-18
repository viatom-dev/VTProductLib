//
//  UIViewController+VTMLanguage.m
//  VTMProductSDK
//

#import "UIViewController+VTMLanguage.h"
#import "VTMLocalization.h"

@implementation UIViewController (VTMLanguage)

- (UIBarButtonItem *)vtm_makeLanguageBarButtonItem {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:VTMLocalized(@"common.language")
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(vtm_languageTapped:)];
    item.accessibilityHint = VTMLocalized(@"common.language.hint");
    return item;
}

- (void)vtm_languageTapped:(UIBarButtonItem *)sender {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:VTMLocalized(@"common.language")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    VTMLanguage current = [VTMLocalization currentLanguage];
    for (NSNumber *value in @[@(VTMLanguageEnglish), @(VTMLanguageChineseSimplified)]) {
        VTMLanguage language = (VTMLanguage)value.integerValue;
        NSString *name = [VTMLocalization nativeNameForLanguage:language];
        NSString *title = language == current ? [NSString stringWithFormat:@"✓ %@", name] : name;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [VTMLocalization setCurrentLanguage:language];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:VTMLocalized(@"common.cancel")
                                              style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.barButtonItem = sender; // iPad
    [self presentViewController:sheet animated:YES completion:nil];
}

@end
