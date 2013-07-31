//
//  RecordAudio.m
//  JuuJuu
//
//  Created by xiaoguang huang on 11-12-19.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "RecordAudio.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "amrFileCodec.h"

@implementation RecordAudio
@synthesize delegate;
@synthesize recorder;

#pragma mark- Life Circle
- (void)dealloc
{
	recordedTmpFile = nil;
    
    [avPlayer stop];
    [avPlayer release];
    avPlayer = nil;
    
    self.delegate = nil;
    self.recorder = nil;
    
    [super dealloc];
}

-(id)init
{
    self = [super init];
    if (self)
    {
        /*
        AVAudioSession * audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error: &error];
        
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
								 sizeof (audioRouteOverride),
								 &audioRouteOverride);
        
        [audioSession setActive:YES error: &error];
         */
    }
    return self;
}

#pragma mark- Public Methods
-(void) startRecord
{
    NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                   //[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                   [NSNumber numberWithFloat:8000.00], AVSampleRateKey,
                                   [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                   //  [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                   [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                   [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                   nil];
    
    recordedTmpFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"caf"]]];
    NSLog(@"Using Temp File called: %@",recordedTmpFile);
    
    
    self.recorder = [[[AVAudioRecorder alloc] initWithURL:recordedTmpFile settings:recordSetting error:&error] autorelease];
    recorder.meteringEnabled = YES;
    NSLog(@"1");
    [recorder prepareToRecord];
    NSLog(@"2");
    [recorder record];
    NSLog(@"3");
}

- (NSURL *) stopRecord
{
    NSURL *url = [[NSURL alloc] initWithString:recorder.url.absoluteString];
    [recorder stop];
    self.recorder = nil;
    return [url autorelease];
}

-(void) play:(NSData*) data
{
	//Setup the AVAudioPlayer to play the file that we just recorded.
    if (avPlayer!=nil)
    {
        [self stopPlay];
        return;
    }
    NSLog(@"start decode");
    NSData* o = [self decodeAmr:data];
    NSLog(@"end decode");
    avPlayer = [[AVAudioPlayer alloc] initWithData:o error:&error];
    avPlayer.delegate = self;
	[avPlayer prepareToPlay];
    [avPlayer setVolume:1.0];
	if(![avPlayer play])
    {
        [self sendStatus:1];
    } else {
        [self sendStatus:0];
    }
}

-(void) stopPlay
{
    if (avPlayer!=nil)
    {
        [avPlayer stop];
        [avPlayer release];
        avPlayer = nil;
        [self sendStatus:1];
    }
}

-(NSData *)decodeAmr:(NSData *)data
{
    if (!data)
    {
        return data;
    }
    return DecodeAMRToWAVE(data);
}

#pragma mark- Private Methods
//0 播放 1 播放完成 2出错
-(void)sendStatus:(int)status
{
    if ([self.delegate respondsToSelector:@selector(RecordStatus:)])
    {
        [self.delegate RecordStatus:status];
    }

    if (status!=0)
    {
        if (avPlayer!=nil)
        {
            [avPlayer stop];
            [avPlayer release];
            avPlayer = nil;
        }
    }
}

+(NSTimeInterval) getAudioTime:(NSData *) data
{
    NSError * error;
    AVAudioPlayer*play = [[AVAudioPlayer alloc] initWithData:data error:&error];
    NSTimeInterval n = [play duration];
    [play release];
    return n;
}

#pragma mark- AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self sendStatus:1];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [self sendStatus:2];
}

@end
