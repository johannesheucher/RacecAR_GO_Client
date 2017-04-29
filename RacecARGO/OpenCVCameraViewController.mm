//
//  OpenCVCameraViewController.m
//  RacecARGO
//
//  Created by Johannes Heucher on 01.02.17.
//  Copyright © 2017 Johannes Heucher. All rights reserved.
//


#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/imgcodecs/ios.h>
#endif

#import "OpenCVCameraViewController.h"

#import "VMMRecognizer.h"
#import "NumberPlateExtractorProxy.h"        // just for testing
#import "TCPSocketRequester.h"


@interface OpenCVCameraViewController () <CvVideoCameraDelegate, VMMRecognizerDelegate, TCPSocketStatusDelegate> {
    CvVideoCamera* videoCamera;
    VMMRecognizer* vMMRecognizer;
    cv::Mat cropped;
}

@property CvVideoCamera* videoCamera;

@end

@implementation OpenCVCameraViewController

@synthesize videoCamera;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // camera and video
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    self.videoCamera.delegate = self;
    
    
    // scene overlay
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"Models/VW_Kaefer" withExtension:@"obj"];
    MDLAsset* asset = [[MDLAsset alloc] initWithURL:url];
    MDLMesh* mesh = (MDLMesh*)[asset objectAtIndex:0];
    
    SCNNode* cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    cameraNode.position = SCNVector3Make(0, 0, 5);
    
    SCNScene* scene = [[SCNScene alloc] init];
    SCNNode* node = [SCNNode nodeWithMDLObject:mesh];
    
    [scene.rootNode addChildNode:cameraNode];
    [scene.rootNode addChildNode:node];
    
    sceneView.autoenablesDefaultLighting = YES;
    sceneView.allowsCameraControl = YES;
    sceneView.scene = scene;
    sceneView.backgroundColor = [UIColor clearColor];
    
    
    // recognition
    self->vMMRecognizer = [[VMMRecognizer alloc] initWithDelegate:self];
    
    
    
    // TODO DEBUG initialize requester here to build up TCP connection
    [TCPSocketRequester defaultRequester];
}


#ifdef __cplusplus
- (void)processImage:(cv::Mat&)image {
    // crop to fit image view
    int width  = (int)self->imageView.bounds.size.width * 2;
    int height = (int)self->imageView.bounds.size.height * 2;
    cropped = image(cv::Rect(0, 0, width, height));
    cv::cvtColor(cropped, image, CV_BGR2RGB);
    
    // TODO DEBUG as long as the real number plate recognition is bad, use proxy
    cv::Rect numberPlateRect = [NumberPlateExtractorProxy extractFrom:image];
    if (numberPlateRect.width > 0) {
        cv::rectangle(image, numberPlateRect, cv::Scalar(200, 100, 255), 5);
    }
}
#endif


- (IBAction)start:(id)sender {
    [self.videoCamera start];
}


- (IBAction)stop:(id)sender {
    [self.videoCamera stop];
}


- (IBAction)capture:(id)sender {
    cv::Mat grayImage;
    
    // turn to gray for VMMR
    cv::cvtColor(cropped, grayImage, CV_BGR2GRAY);
    
    
    // TEST: write and read
    //    std::vector<uchar> array;
    //    if (grayImage.isContinuous()) {
    //        array.assign(grayImage.datastart, grayImage.dataend);
    //    }
    //    for (int i = 100 * image.cols; i < 140 * image.cols; i++) {
    //        array[i] = 0;
    //    }
    //    cv::Mat loadedImage = cv::Mat(image.rows, image.cols, CV_8UC1);
    //    memcpy(loadedImage.data, array.data(), array.size() * sizeof(uchar));
    // ---
    cv::Rect numberPlateRect = [NumberPlateExtractorProxy extractFrom:grayImage];
    if (numberPlateRect.width > 0) {
        [self->vMMRecognizer recognize:grayImage withNumberPlateRect:numberPlateRect];
    }
    makeModelLabel.text = @"Recognizing ...";
}


#pragma mark - VMMRecognitionDelegate

- (void)recognizedMake:(NSString*)make andModel:(NSString*)model {
    makeModelLabel.text = [NSString stringWithFormat:@"%@ %@", make, model];
}


#pragma mark - Socket Status

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TCPSocketRequester defaultRequester] addSocketStatusDelegate:self];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[TCPSocketRequester defaultRequester] removeSocketStatusDelegate:self];
}

- (void)statusUpdate:(NSString*)status {
    self.navigationItem.rightBarButtonItem.title = status;
}

@end
