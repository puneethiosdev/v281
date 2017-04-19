//
//  OEXNetworkConstants.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 22/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#ifndef edXVideoLocker_NetworkConstants_h
#define edXVideoLocker_NetworkConstants_h

//NSNotification center constants
#define DOWNLOAD_PROGRESS_NOTIFICATION @"downloadProgressNotification"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TASK @"downloadProgressNotificationTask"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_WRITTEN @"downloadProgressNotificationTotalBytesWritten"
#define DOWNLOAD_PROGRESS_NOTIFICATION_TOTAL_BYTES_TO_WRITE @"downloadProgressNotificationTotalBytesToWrite"

#define REQUEST_USER_DETAILS @"User details"
#define REQUEST_COURSE_ENROLLMENTS @"Courses user has enrolled in"

// edX Constants

// TODO: move the remaining things that mention edx.org into config
#define URL_EXTENSION_VIDEOS @".mp4"
#define URL_EXCHANGE_TOKEN @"/oauth2/exchange_access_token/{backend}/"
#define URL_USER_DETAILS @"/api/mobile/v0.5/users"
#define URL_COURSE_ENROLLMENTS @"/course_enrollments/"
#define URL_VIDEO_SUMMARY @"/api/mobile/v0.5/video_outlines/courses/"
#define URL_COURSE_HANDOUTS @"/handouts"
#define URL_COURSE_ANNOUNCEMENTS @"/updates"
#define URL_RESET_PASSWORD  @"/password_reset/"
#define URL_SUBSTRING_VIDEOS @"edx-course-videos"
#define URL_SUBSTRING_ASSETS @"asset/"
#define AUTHORIZATION_URL @"/oauth2/access_token"
#define URL_GET_USER_INFO @"/api/mobile/v0.5/my_user_info"
// For Closed Captioning
#define URL_VIDEO_SRT_FILE @"/api/mobile/v0.5/video_outlines/transcript/"
#define URL_COURSE_ENROLLMENT @"/api/enrollment/v1/enrollment"
#define URL_COURSE_ENROLLMENT_EMAIL_OPT_IN @"/api/user_api/v1/preferences/email_opt_in"
#define SIGN_UP_URL @"/user_api/v1/account/registration/"

//kAMAT_CHANGES 2.0
#define kVERSION_ALERT_TEXT1 @"Newer version appliedx app"
#define kVERSION_ALERT_TEXT2 @"is now available. Tap on update to install"

//kAMAT_CHANGES 2.0
#define kAMAT_CHANGES @"AMAT_CHANGES"
#define kAMAT_DEBUG @"AMAT_DEBUG"
#define VPN_ALERT_TAG 2121
#define SIGN_UP_ALERT_TAG 3131
#define VERSION_ALERT_TAG 4141


#define VIDEO_SIGNED_URL @"sign_url?url="
#define CLOUD_FRONT_HOST_NAME @"d2a8rd6kt4zb64.cloudfront.net"
#define UNDEFINED_USER @"undefined"
#define PULSE_SECURE_URL_SCHEMA @"pulsesecure://"

//////VPC Dev
//#define kAppName @"Vappliedx"
//#define SERVER_URL @"https://appliedxvpcdev.amat.com/"
//#define PING_SSO_URL @"https://appliedxvpcdev.amat.com/auth/login/tpa-saml/?auth_entry=login&next=/mobileappredirect&idp=pingsso"
//#define APP_SCHEMA_URL @"appliedx://?"
//#define VERSION_CHECK_URL @"https://appliedxvpcdev.amat.com/latest_app_version"
////#define kDownloadURLForProduction @"https://devvsp01.amat.com/mifs/asfV3x/appstore?clientid=1073760408&vspver=7.5.0.0"
//#define kDownloadURLForProduction @"https://portal.fei.msua01.manage.microsoft.com/Apps#All" //Intune download
//#define kFILTER_COURSES @"https://appliedxvpcdev.amat.com/search_courses"

//Production
 #define kAppName @"appliedx"
 #define SERVER_URL @"https://appliedx.amat.com/"
 #define PING_SSO_URL @"https://appliedx.amat.com/auth/login/tpa-saml/?auth_entry=login&next=/mobileappredirect&idp=pingsso"
 #define APP_SCHEMA_URL @"appliedxproduction://?"
 #define VERSION_CHECK_URL @"https://appliedx.amat.com/latest_app_version"
// #define kDownloadURLForProduction @"https://mivsp01.amat.com/mifs/asfV3x/appstore?clientid=1073760408&vspver=7.5.0.0" //MI
 #define kDownloadURLForProduction @"https://portal.fei.msua01.manage.microsoft.com/Apps#All" //Intune download
 #define kFILTER_COURSES @"https://appliedx.amat.com/search_courses"


////Production VR
// #define kAppName @"appliedx"
// #define SERVER_URL @"https://appliedx.amat.com/"
// #define PING_SSO_URL @"https://appliedx.amat.com/auth/login/tpa-saml/?auth_entry=login&next=/mobileappredirect&idp=pingsso"
// #define APP_SCHEMA_URL @"appliedxproduction://?"
// #define VERSION_CHECK_URL @"https://appliedx.amat.com/latest_app_version_vr"
// #define kDownloadURLForProduction @"https://portal.fei.msua01.manage.microsoft.com/Apps#All" //Intune download
//// #define kDownloadURLForProduction @"https://mivsp01.amat.com/mifs/asfV3x/appstore?clientid=1073760408&vspver=7.5.0.0"
// #define kFILTER_COURSES @"https://appliedx.amat.com/search_courses?search_string=360"


//CEO- Check -  To check the VPN Availability.
#define VPN_CHECK_URL @"https://myid.amat.com:4431/IdentityWebService.svc/Person/?filter=DisplayName contains Gary Dickerson&sortBy=DisplayName&sortOrder=ASC&attributes=DisplayName&pageNumber=1&pageSize=1"
// SSO Generic User name & Password
#define GENRIC_USERNAME @"Identity_WsUser"
#define GENRIC_PASSWORD @"!dent1ty@123"


#endif
