//
//  WakariyasuiCommitPopup.m
//  WakariyasuiCommitPopup


#import "WakariyasuiCommitPopup.h"


@implementation WakariyasuiCommitPopup


#ifndef REPFUNCDEFd
#define REPFUNCDEFd
#define RMF(aClass, origSel, repFunc) Replace_MethodImp_WithFunc(aClass, origSel, repFunc)
#define RCMF(aClass, origSel, repFunc) Replace_ClassMethodImp_WithFunc(aClass, origSel, repFunc)
#endif

IMP Replace_MethodImp_WithFunc(Class aClass, SEL origSel, const void* repFunc)
{
    Method origMethod;
    IMP oldImp = NULL;
    
    if (aClass && (origMethod = class_getInstanceMethod(aClass, origSel))){
        oldImp=method_setImplementation(origMethod, repFunc);
    }
    
    return oldImp;
}


IMP Replace_ClassMethodImp_WithFunc(Class aClass, SEL origSel, const void* repFunc)
{
    Method origMethod;
    IMP oldImp = NULL;
    
    if (aClass && (origMethod = class_getClassMethod(aClass, origSel))){
        oldImp=method_setImplementation(origMethod, repFunc);
    }

    return oldImp;
}


static NSString* WCPNameForIDESourceControlRevision(id rep)
{
    if ([[rep className]isEqualToString:@"IDESourceControlRevision"]
        && [rep respondsToSelector:NSSelectorFromString(@"isCurrent")]
        && [rep respondsToSelector:NSSelectorFromString(@"isBASE")]
        && [rep respondsToSelector:NSSelectorFromString(@"isHEAD")]
        && [rep respondsToSelector:NSSelectorFromString(@"message")]
        && [rep respondsToSelector:NSSelectorFromString(@"date")]
        && [rep respondsToSelector:NSSelectorFromString(@"author")]
        && [rep respondsToSelector:NSSelectorFromString(@"revision")]
    ) {
        NSDate* date=objc_msgSend(rep, NSSelectorFromString(@"date"));
        NSString* dateString=nil;
        if (date) {
            dateString=[date descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
        }else{
            //Local Revision
            return nil;
        }
        
        NSString* isCurrent=@"";
        NSString* isBASE=@"";
        NSString* isHEAD=@"";
        if (objc_msgSend(rep, NSSelectorFromString(@"isCurrent"))) {
            isCurrent=@"[B,H]";
        } else {
            if (objc_msgSend(rep, NSSelectorFromString(@"isBASE"))) isBASE=@"[B]";
            if (objc_msgSend(rep, NSSelectorFromString(@"isHEAD"))) isHEAD=@"[H]";
        }
        
        NSString* message=objc_msgSend(rep, NSSelectorFromString(@"message"));
        if (!message) message=@"";
        NSString* author=objc_msgSend(rep, NSSelectorFromString(@"author"));
        if (!author) author=@"";
        NSString* revision=objc_msgSend(rep, NSSelectorFromString(@"revision"));
        if (!revision) revision=@"";
        
        //shorten revision
        if ([revision length]>7) revision=[revision substringToIndex:7];
        //shorten message
        if ([message length]>50) message=[[message substringToIndex:47]stringByAppendingString:@"..."];
        
        //PathControl can't draw multi-line
        message=[message stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        
        //I don't need author
        author=@"";
        
        return [NSString stringWithFormat:@"%@ %@[%@] %@ %@%@%@", dateString, author, revision, message, isCurrent, isBASE, isHEAD];
    }
    
    return nil;
}


//IDESourceControlRevision navigableItem_name
static NSString* (*orig_navigableItem_name)(id, SEL);
static NSString* WCP_navigableItem_name(id self, SEL _cmd)
{
    NSString* name=WCPNameForIDESourceControlRevision(self);
    if (name) {
        return name;
    }

    return orig_navigableItem_name(self, _cmd);
}

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle]infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            orig_navigableItem_name = (NSString* (*)(id, SEL))RMF(
                NSClassFromString(@"IDESourceControlRevision"),
                NSSelectorFromString(@"navigableItem_name"), WCP_navigableItem_name);
        });
    }
}


@end
