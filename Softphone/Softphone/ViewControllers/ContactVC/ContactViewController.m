//
//  ContactViewController.m
//  Softphone
//
//  Created by Hoang Duoc on 3/5/18.
//  Copyright © 2018 Hoang Duoc. All rights reserved.
//

#import "ContactViewController.h"
#import <AddressBook/AddressBook.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABPerson.h>
#import <Contacts/Contacts.h>
#import "Constants.h"
#import "Utils.h"
#import "ContactModel.h"
#import "SPManager.h"
#import "ContactTableViewCell.h"
#import "StringeeImplement.h"
#import "GlobalService.h"

@interface ContactViewController ()

@end

@implementation ContactViewController {
    UISearchController *searchController;
    NSMutableArray *arrayResults;
    BOOL isSearching;
    CGFloat headerHeight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [SPManager instance].contactViewController = self;
    arrayResults = [[NSMutableArray alloc] init];
    headerHeight = 20;
    if (@available(iOS 11.0, *)) {
        self.searchViewHeightConstraint.constant = 56;
    }
    
    [self.tblContact registerNib:[UINib nibWithNibName:@"ContactTableViewCell" bundle:nil] forCellReuseIdentifier:@"contactCell"];
    self.tblContact.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tblContact.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    [self getPrivateContact];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self createSearchbar];
}


// MARK:- Actions

- (void)hideSearchController {
    [searchController setActive:NO];
    [searchController.searchBar resignFirstResponder];
    isSearching = NO;
    [self checkReloadData];
}

- (void)getPrivateContact {
    
    if (@available(iOS 9, *)) {
        // Kiểm tra quyền truy cập tới danh bạ
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        
        if (status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusRestricted) {
            [self handleWithContactPermission];
            return;
        }
        
        [Utils showProgressViewWithString:@"" inView:self.view];
        
        CNContactStore *store = [[CNContactStore alloc] init];
        [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            // make sure the user granted us access
            if (!granted) {
                [Utils hideProgressViewInView:self.view];
                return;
            }
            
            // build array of contacts
            
            NSMutableArray *contacts = [NSMutableArray array];
            
            NSError *fetchError;
            CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactIdentifierKey, [CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName], CNContactPhoneNumbersKey]];
            
            BOOL success = [store enumerateContactsWithFetchRequest:request error:&fetchError usingBlock:^(CNContact *contact, BOOL *stop) {
                [contacts addObject:contact];
            }];
            if (!success) {
                [Utils hideProgressViewInView:self.view];
                NSLog(@"error = %@", fetchError);
            }
            
            NSMutableArray *phones = [[NSMutableArray alloc] init];
            NSMutableArray *privateContacts = [[NSMutableArray alloc] init];
            
            // you can now do something with the list of contacts, for example, to show the names
            CNContactFormatter *formatter = [[CNContactFormatter alloc] init];
            
            for (CNContact *contact in contacts) {
                NSString * username = @"";
                NSString * phoneNumber = @"";
                
                username = [formatter stringFromContact:contact];
                
                NSArray * values = contact.phoneNumbers;
                if (values.count) {
                    phoneNumber = (NSString *)[(contact.phoneNumbers[0].value) valueForKey:@"digits"];
                }
                
                [phones addObject:[Utils getPhoneForCall:phoneNumber]];
                ContactModel *privateContact = [[ContactModel alloc] initWithName:username phone:phoneNumber];
                [privateContacts addObject:privateContact];
                //                [[SPManager instance] addPrivateContact:privateContact];
            }
            
            [self checkPhonesExistedWithPrivateContacts:privateContacts phones:phones];
            
        }];
        
    } else {
        
        // Kiểm tra quyền truy cập tới danh bạ
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        
        if (status == kABAuthorizationStatusDenied || status == kABAuthorizationStatusRestricted) {
            
            [self handleWithContactPermission];
            
            return;
        }
        
        if (status != kABAuthorizationStatusAuthorized) {
            ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!granted){
                        // Từ chối truy cập
                        return;
                    }
                });
            });
        }
        
        [Utils showProgressViewWithString:@"" inView:self.view];
        
        CFErrorRef * error = NULL;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
        
        if (!addressBook) {
            NSLog(@"opening address book");
        }
        
        NSMutableArray *phonesToCheck = [[NSMutableArray alloc] init];
        NSMutableArray *privateContacts = [[NSMutableArray alloc] init];
        NSLog(@"numberOfPeople: %ld", numberOfPeople);
        
        for(int i = 0; i < numberOfPeople; i++){
            ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
            
            //Lấy số điện thoại
            ABMultiValueRef phones =(__bridge ABMultiValueRef)((__bridge NSString*)ABRecordCopyValue(person, kABPersonPhoneProperty));
            NSString * phoneNumber = @"";
            for(CFIndex i = 0; i < ABMultiValueGetCount(phones); i++) {
                phoneNumber = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phones, i);
            }
            
            // Lấy tên
            NSString * username = @"";
            CFStringRef firstName, lastName;
            firstName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
            lastName  = ABRecordCopyValue(person, kABPersonLastNameProperty);
            
            if (lastName) {
                username = [username stringByAppendingString:(__bridge NSString * _Nonnull)(lastName)];
            }
            
            if (firstName) {
                username = [username stringByAppendingString:(__bridge NSString * _Nonnull)(firstName)];
            }
            
            [phonesToCheck addObject:[Utils getPhoneForCall:phoneNumber]];
            ContactModel *privateContact = [[ContactModel alloc] initWithName:username phone:phoneNumber];
            [privateContacts addObject:privateContact];
        }
        
        [self checkPhonesExistedWithPrivateContacts:privateContacts phones:phonesToCheck];
        
        [self checkReloadData];
        [Utils hideProgressViewInView:self.view];
    }
}

- (void) handleWithContactPermission {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Truy cập tới danh bạ" message:@"Softphone muốn truy cập danh bạ" preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"Vào cài đặt" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UIApplication *application = [UIApplication sharedApplication];
        
        NSURL *URL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        
        if(@available(iOS 10, *)){
            
            if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                [application openURL:URL options:@{}
                   completionHandler:^(BOOL success) {
                       NSLog(@"Open: %d",success);
                   }];
            } else {
                BOOL success = [application openURL:URL];
                NSLog(@"Open: %d",success);
            }

        }
        else{
            bool can = [application canOpenURL:URL];
            if (can) {
                [application openURL:URL];
            }
            
        }
        
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Hủy" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:TRUE completion:nil];
}

- (void)checkPhonesExistedWithPrivateContacts:(NSMutableArray *)privateContacts phones:(NSMutableArray *)phones {
    
    [GlobalService checkPhoneBookExistedWithPhoneBook:phones token:[SPManager instance].myUser.token completionHandler:^(BOOL status, int code, id responseObject) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status) {
                // Thành công
                NSDictionary *data = (NSDictionary *)responseObject;
                NSArray *phonesExisted = (NSArray *)[data objectForKey:@"phonesExisted"];
                for (NSString *phone in phonesExisted) {
                    for (ContactModel *privateContact in privateContacts) {
                        if ([privateContact.phone_call isEqualToString:phone]) {
                            privateContact.isExistence = YES;
                            break;
                        }
                    }
                }
            } else {
                NSLog(@"%@", (NSString *)responseObject);
            }
            
            for (ContactModel *privateContact in privateContacts) {
                [[SPManager instance] addPrivateContact:privateContact];
            }
            
            [self checkReloadData];
            [Utils hideProgressViewInView:self.view];
        });
    }];
}

- (void)checkReloadData {
    dispatch_async(dispatch_get_main_queue(), ^{
        long amount;
        if (isSearching) {
            amount = arrayResults.count;
        } else {
            amount = [SPManager instance].listKeys.count;
        }
        
        if (amount) {
            self.tblContact.scrollEnabled = YES;
            self.tblContact.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        } else {
            self.tblContact.scrollEnabled = NO;
            self.tblContact.tableFooterView = [self getNoContactView];
        }
        [self.tblContact reloadData];
    });
}

- (UIView *)getNoContactView {
    
    UIView * noContactView = [[UIView alloc] init];
    
    UILabel * content = [[UILabel alloc] init];
    
    content.font = [UIFont systemFontOfSize:25.0];
    content.textAlignment = NSTextAlignmentCenter;
    content.textColor = [UIColor lightGrayColor];
    content.text = @"Không có liên hệ";
    [noContactView addSubview:content];
    
    CGSize size = CGSizeMake(SCR_WIDTH, SCR_HEIGHT - 64 - 44 - 50);
    
    noContactView.frame = CGRectMake(0, 0, size.width, size.height);
    content.frame = CGRectMake(0, - 50 /2.0, size.width, size.height);
    
    return noContactView;
}

- (void)createSearchbar {
    // searchbar
    if (!searchController) {
        
        searchController = [[UISearchController alloc]initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.dimsBackgroundDuringPresentation = NO;
        searchController.hidesNavigationBarDuringPresentation = NO;
        searchController.searchBar.delegate = self;
        [searchController.searchBar sizeToFit];
        [self.searchView addSubview:searchController.searchBar];
    }
    
}

// MARK:- TableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (isSearching) {
        return 1;
    } else {
        return [[SPManager instance].dicSections count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (isSearching) {
        return arrayResults.count;
    } else {
        NSString *key = [[SPManager instance].listKeys objectAtIndex:section];
        NSArray *contactOfSection = [[SPManager instance].dicSections objectForKey:key];
        return contactOfSection.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ContactTableViewCell *contactCell = [tableView dequeueReusableCellWithIdentifier:@"contactCell" forIndexPath:indexPath];
    ContactModel *contact;
    if (isSearching) {
        contact = [arrayResults objectAtIndex:indexPath.row];
    } else {
        NSString *key = [[SPManager instance].listKeys objectAtIndex:indexPath.section];
        NSArray *contactOfSection = [[SPManager instance].dicSections objectForKey:key];
        contact = [contactOfSection objectAtIndex:indexPath.row];
    }
    [contactCell configureCellWithContact:contact];
    
    return contactCell;
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (isSearching) {
        return 0;
    } else {
        return headerHeight;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCR_WIDTH, headerHeight)];
    headerView.backgroundColor = [Utils colorWithHexString:@"f4f7f8"];
    
    UILabel * labelHeader = [[UILabel alloc] initWithFrame:CGRectMake(10, 3, SCR_WIDTH - 10, headerHeight - 6)];
    labelHeader.textColor = [UIColor lightGrayColor];
    labelHeader.font = [UIFont boldSystemFontOfSize:12];
    labelHeader.text = [[SPManager instance].listKeys objectAtIndex:section];
    
    [headerView addSubview:labelHeader];
    
    return headerView;
}

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (isSearching) {
        return nil;
    } else {
        return [SPManager instance].listKeys;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

}

// MARK:- Search

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (searchController.active) {
        isSearching = YES;
        [self filterContentForSearchtext:searchController.searchBar.text];
        [self checkReloadData];
    }
}

-(void)filterContentForSearchtext:(NSString *)searchText {
    [arrayResults removeAllObjects];
    
    // Chuyển text có dấu tiếng việt về ko dấu để so sánh
    NSString * unAccentedSearchText = [searchText stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
    NSString * resultSearchText = [unAccentedSearchText capitalizedString];
    
    for (NSString *key in [SPManager instance].listKeys) {
        NSArray *contactOfSection = [[SPManager instance].dicSections objectForKey:key];
        for (ContactModel *contactModel in contactOfSection) {
            NSString * accentedName = contactModel.name;
            NSString * unAccentedName = [accentedName stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
            NSString * resultName = [unAccentedName capitalizedString];
            
            NSString * accentedPhoneNumber = contactModel.phone_display;
            NSString * unAccentedPhone = [accentedPhoneNumber stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
            NSString * resultPhone = [unAccentedPhone capitalizedString];
            
            NSRange name = [resultName rangeOfString:resultSearchText options:(NSCaseInsensitiveSearch)];
            NSRange phone = [resultPhone rangeOfString:resultSearchText options:(NSCaseInsensitiveSearch)];
            
            if (name.length > 0 || phone.length > 0) {
                [arrayResults addObject:contactModel];
            }
        }
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    isSearching = NO;
    [self checkReloadData];
}
@end
