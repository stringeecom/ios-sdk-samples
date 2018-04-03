
// Determine which environment we are running in for APNS
# ifdef isRunningInDevModeWithDevProfile
#     define isProductionMode NO
#else
#    define isProductionMode YES
#endif

// Device
#define SCR_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCR_HEIGHT [UIScreen mainScreen].bounds.size.height
#define IS_IPHONE UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone

// Setting
#define PRIMARY_COLOR @"007ce2"
#define HEADER_COLOR @"f4f7f8"


