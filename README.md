## Hi there 👋

RsyncOSX and RsyncUI are GUI´s on the Apple macOS plattform for the command line tool [rsync](https://github.com/WayneD/rsync). 

It is `rsync` which executes the synchronize task. The GUI´s are only for setting parameters and make it more easy to use `rsync`, which is a fantastic tool.

### Very important to read and understand

The UI of RsyncOSX and RsyncUI can for users who dont know `rsync` be difficult to understand. Setting wrong parameters to rsync can result in deleted data. RsyncOSX nor RsyncUI will not stop you for doing so. That is why it is **very** important to execute a simulated run, a `--dry-run`, and verify the result before the real run.

Please read  the [documentation of RsyncOSX](https://rsyncosx.netlify.app/) or [documentation of RsyncUI](https://rsyncui.netlify.app/) for how to add a task and how to execute a simulated run, a `--dry-run`, to verify the task.  

### Version of macOS

If you have installed **macOS Big Sur**, RsyncOSX is the GUI for you. If you have installed **macOS Monterey** or **macOS Ventura**, you can use both GUI´s in parallell.

### External task does the job

Please be aware it is an external task **not controlled** by RsyncOSX nor RsyncUI which executes the command line tool `rsync`. RsyncOSX and RsyncUI are monitoring the task for progress and termination. The user can abort a tasks at any time. Please let the abort to finish and cleanup properly before starting a new task. It might take a few seconds. If not the apps might become unresponsive.

One of many advantages of utilizing `rsync` is that it can restart and continue the synchronize task from where it was aborted.

### RsyncOSX

RsyncOSX is the only GUI which supports scheduling of task.

[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncOSX)](https://github.com/rsyncOSX/RsyncOSX/blob/master/Licence.MD) ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncOSX/v6.7.5/total) ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncOSX/v6.7.4/total) [![Netlify Status](https://api.netlify.com/api/v1/badges/d375f6d7-dc9f-4913-ab43-bfd46d172eb2/deploy-status)](https://app.netlify.com/sites/rsyncosx/deploys) [![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncOSX)](https://github.com/rsyncOSX/RsyncOSX/issues)

**RsyncOSX** is released for **macOS Big Sur** and later. Latest build is [18 November 2022](https://github.com/rsyncOSX/RsyncOSX/releases).

- the [documentation of RsyncOSX](https://rsyncosx.netlify.app/)
- the [readme for RsyncOSX](https://github.com/rsyncOSX/RsyncOSX/blob/master/RsyncOSX.md)
- the [changelog](https://rsyncosx.netlify.app/post/changelog/)

![](images/rsyncosx.png)

### RsyncUI

[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/blob/main/Licence.MD)  ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncUI/v1.4.0/total) ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncUI/v1.3.9/total)  [![Netlify Status](https://api.netlify.com/api/v1/badges/1d14d49b-ff14-4142-b135-771db071b58a/deploy-status)](https://app.netlify.com/sites/rsyncui/deploys) [![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/issues)

**RsyncUI** is released for **macOS Monterey** and later. Latest build is [6 December 2022](https://github.com/rsyncOSX/RsyncUI/releases).

- the [documentation of RsyncUI](https://rsyncui.netlify.app/)
- the [readme for RsyncUI](https://github.com/rsyncOSX/RsyncUI/)
- the [changelog](https://rsyncui.netlify.app/post/changelog/)

![](images/rsyncui.png)

![My github stats](https://github-readme-stats.vercel.app/api?username=rsyncOSX&show_icons=true&hide_border=true&theme=dark)

![Metrics](https://metrics.lecoq.io/rsyncOSX?template=classic&config.timezone=Europe%2FOslo)
