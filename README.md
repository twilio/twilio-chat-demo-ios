# IP Messaging Demo Application Overview

## Getting Started

Welcome to the IP Messaging Demo application.  This application demonstrates a basic chat client with the ability to create and join channels, invite other members into the channels and exchange messages.

What you'll minimally need to get started:

- A clone of this repository
- [A way to create an IP Messaging Service Instance and generate client tokens](https://www.twilio.com/docs/ip-messaging/quickstart/js/1-getting-started)
- The .framework file from the [IP Messaging client for iOS distribution](https://www.twilio.com/docs/ip-messaging/sdks)

The first step is to bring the .framework into the project.  The easiest way to do this is to find the .framework in the tar.bz distribution and drag-n-drop it into the project navigator, next to the existing libc++.dylib reference is a good spot.

Next, in the ChannelListViewController.m file, find the line that Xcode will let you know is an error.  Delete that #error line and fill in a client token in the line below:

        NSString *token = @"";

You can either paste in a client token you have generated elsewhere or update this portion of code to call out to a webservice you control that can generate tokens.

