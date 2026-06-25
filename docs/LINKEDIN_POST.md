# LinkedIn Post Draft

I built OpsPulse, a native iOS incident-management and service-reliability app for DevOps/SRE workflows.

It helps engineering teams view service health, active incidents, SLO metrics, burn rate, runbook progress, and post-incident review data from a mobile interface. The app runs in offline demo mode with deterministic data, includes tested incident workflow logic, WidgetKit support, App Intents, and simulator build/launch scripts.

What I focused on:

- SwiftUI iPhone/iPad app structure
- SLO and error-budget calculations
- Incident commander workflow
- Runbook checklist flow
- Reliability simulation lab
- Real iPhone Simulator screenshots
- Repeatable Xcode build and launch scripts

Screenshots and source code are available on GitHub. Developers with Mac and Xcode can clone the repo and run it in the iPhone Simulator:

```bash
git clone https://github.com/Nagadeepak1998/opspulse-ios.git
cd opspulse-ios
scripts/test.sh
scripts/build_and_launch.sh
```

GitHub: https://github.com/Nagadeepak1998/opspulse-ios

Note: Direct installation on other people's iPhones would require TestFlight or App Store distribution. For this portfolio version, the public access path is GitHub source code, screenshots, and Xcode Simulator testing.
