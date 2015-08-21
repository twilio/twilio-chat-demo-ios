# IP Messaging Demo Application Overview

## Getting Started

Welcome to the IP Messaging Demo application, or IPM Demo for short.  This application demonstrates a basic chat client with the ability to create and join channels, invite other members into the channels and exchange messages.

What you'll minimally need to get started:

- A clone of this repository
- A way to generate client tokens

In the ChannelListViewController.m file, find the line that Xcode will let you know is an error.  Delete that #error line and fill in a client token in the line below:

        NSString *token = @"";

You can either paste in a client token you have generated elsewhere or update this portion of code to call out to a webservice you control that can generate tokens.

