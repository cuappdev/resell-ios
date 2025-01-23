# Resell - Cornell Marketplace

<p align="center"><img src="https://github.com/cuappdev/assets/blob/master/app-icons/resell-icon.png" width=210 /></p>

Resell is an app that collects, filters, and compares different items that people want to resell in order to connect sellers with buyers and to facilitate resource utilization. Resell is one of the latest apps by [Cornell AppDev](http://cornellappdev.com), an engineering project team at Cornell University focused on mobile app development. It is Cornell AppDev's first app built using React Native to support both iOS and Android platforms simultaneoulsy, reduce code duplication, and ensure consistency across platforms. Download the current release on the [App Store](https://apps.apple.com/us/app/resell-cornell-marketplace/id1622452299)!

<br />

## Using Firebase

Resell uses two databases per environment. We have a PostgreSQL database that is associated with our Digital Ocean backend server. We also have a Firebase Firestore database (a NoSQL database) under the Resell Firebase project in our Cornell AppDev Google acount.

For Firestore, the `(default)` database corresponds to our development environment and `resell-prod` corresponds to production. **Please be aware of which database to use since frontend is responsible for managing data in Firestore.**

## Importing Environment Variables and Secrets
Download `Keys.xcconfig` and place it in the main repo directory

Download `GoogleService-Info.plist` and `resell-service.json` and place both files in a `Supporting` folder in the `Resell` directory.

For AppDev members, you can find these pinned in the `#resell-frontend` Slack channel.
- GoogleService-Info.plist
- resell-service.json
- Keys.xcconfig
