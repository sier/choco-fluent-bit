<p align="center">
		<picture>
		  <a href="https://fluentbit.io">	<img src="https://fluentbit.io/images/footer-logo.svg" alt="Fluent Bit" width="450"> </a>
		</picture>
    <picture>
      <a href="https://community.chocolatey.org/packages/fluent-bit/"> <img src="https://chocolatey.org/assets/images/global-shared/logo-square.svg" alt="Chocolatey" width="150"> </a>
    </picture>
</p>

<hr>
<p align="center">The <b>unofficial</b> Chocolatey package for Fluent Bit</p>
<p align="center">Fluent Bit is a super fast, lightweight, and highly scalable logging, metrics, and traces processor and forwarder. It is the preferred choice for cloud and containerized environments.</p>
<p align="center">
  <a href="https://community.chocolatey.org/packages/fluent-bit"><img alt="Chocolatey Version" src="https://img.shields.io/chocolatey/v/fluent-bit"></a>
</p>



# Getting Started

- [Prerequisites](#prerequisites)
- [Install](#install)
- [Build from source](#build-from-source)

## Prerequisites

- [Chocolatey](https://chocolatey.org/install)

## Install

The chocolatey package can either be:
* Downloaded from the chocolatey community repository found here: https://community.chocolatey.org/packages/fluent-bit/
  Direct install command:
  ```
  choco install fluent-bit
  ```
  OR
* Downloaded from the releases page of this GitHub repo found here: https://github.com/sier/choco-fluent-bit/releases
  ```
  cd <DOWNLOAD LOCATION>
  choco install fluent-bit --source .
  ```


## Build from source

```
git clone https://github.com/sier/choco-fluent-bit.git
cd choco-fluent-bit
choco pack --outputdirectory build
```

To install the package using debug mode:
```
choco install fluent-bit --debug --verbose --source .
```
