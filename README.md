# Chat Demo Application Overview

## Getting Started

Welcome to the Chat Demo application.  This application demonstrates a basic chat client with the ability to create and join channels, invite other members into the channels and exchange messages.

What you'll minimally need to get started:

- A clone of this repository
- [Learn about the Chat system and how to create instances](https://www.twilio.com/docs/api/chat/guides/chat-fundamentals)
- [How to create tokens](https://www.twilio.com/docs/api/chat/guides/create-tokens)
- The .framework file from the [Chat client for iOS distribution](https://www.twilio.com/docs/api/chat/sdks)

The first step is to bring the .framework into the project.  The easiest way to do this is to find the .framework in the tar.bz distribution and drag-n-drop it into the target's Embedded Frameworks section on the General settings tab.

Next, in the ChatManager.m file, find the line that Xcode will let you know is an error.  Delete that #error line and fill in a client token in the line below:

        return nil;

You can either paste in a client token you have generated elsewhere or update this portion of code to call out to a webservice you control that can generate tokens.

## Additional Configuration of Chat Instance

In order to allow members of a channel other than a message's original author to add reactions to messages in this demo, you will need to permit any channel member to modify a message's attributes.  In a non-sample application, this could be handled more securely with a call initiated by your backend server and the system user should you wish to use message attributes for sensitive data that an arbitrary channel member should not be able to modify.

To learn more about Roles and Channels, you can [visit the Role documentation](https://www.twilio.com/docs/api/chat/rest/roles#action-update).  A quick example of enabling editing of any message's attributes using curl is:

    curl -XPOST https://chat.twilio.com/v1/Services/{service sid}/Roles/{role sid} \
        -d "FriendlyName=channel user" \ 
        -d "Permission=sendMessage" \ 
        -d "Permission=leaveChannel" \ 
        -d "Permission=editOwnMessage" \ 
        -d "Permission=editOwnMessageAttributes" \ 
        -d "Permission=deleteOwnMessage" \ 
        -d "Permission=editAnyMessageAttributes" \ 
        -u '{twilio account sid}:{twilio auth token}'
