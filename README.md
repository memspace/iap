Flutter plugin for interacting with iOS StoreKit and Android Billing Library.

Work in progress. Not much can be found here yet.

### How this plugin is different from others

The main difference is that this plugin does **not** provide common
interface for interacting with Andoid and iOS payment APIs. The reason is simply 
because those APIs have very little in common, so defining a common interface would
suffer from many inconsistencies and limitations.

> This clearly goes against best practices [described by a Google engineer](good-plugins).
> However I believe this is a rare case where it is more beneficial to
> take a slightly different path. Similarly to how [device_info]() plugin did.

[good-plugins]: https://medium.com/flutter-io/writing-a-good-flutter-plugin-1a561b986c9c?linkId=57996885
[device_info]: https://pub.dartlang.org/packages/device_info

Instead this plugin aims to provide two distinct interfaces for iOS StoreKit
and Android BillingClient. This way we can expose complete feature set
for both platforms. It is up to the user of this plugin to define a unified
interface inside their app which suites their workflow best.

There is additional benefit of having the same API interface in your Dart code
as you can rely on a lot of information available in official docs as well as
on the Internet. This makes it easier to get started and learn.

All Dart code is thoroughly documented with information taken directly from 
Apple developers website (for StoreKit).

### Status

Current version only implements iOS portion with Android side coming next.
