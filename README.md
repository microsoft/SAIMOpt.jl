# SAIMOpt.jl

## Introduction

TODO: Give a short introduction of your project. Let this section explain the objectives or the motivation behind this project.

## Getting Started

TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:

1. Installation process
2. Software dependencies
3. Latest releases
4. API references

## Central Feed Services (CFS) - Engineering Systems Standard Requirement

CFS onboarding required configuring your project to only consume packages through Azure Artifacts. This is an engineering system standard which is required company-wide.

1. If your project uses NuGet packages, update the nuget.config file placed at the root of this repository to use your preferred feed.
2. If your project uses npm packages, consult [this section of the CFS documentation](https://aka.ms/cfs). Feel free to delete the nuget.config file in this repository.
3. If your project uses Maven packages, consult [this section of the CFS documentation](https://aka.ms/cfs). Feel free to delete the nuget.config file in this repository.
4. If your project uses Pip packages, consult [this section of the CFS documentation](https://aka.ms/cfs). Feel free to delete the nuget.config file in this repository.
5. If your project uses Rust (Cargo) crates, consult [this section of the CFS documentation](https://aka.ms/cfs). Feel free to delete the nuget.config file in this repository.

## Build and Test

TODO: Describe and show how to build your code and run the tests.

## Contribute

TODO: Explain how other users and developers can contribute to make your code better.

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:

- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)


<!-- Tidyverse lifecycle badges, see https://www.tidyverse.org/lifecycle/ Uncomment or delete as needed. -->
![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)<!--
![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)
![lifecycle](https://img.shields.io/badge/lifecycle-stable-green.svg)
![lifecycle](https://img.shields.io/badge/lifecycle-retired-orange.svg)
![lifecycle](https://img.shields.io/badge/lifecycle-archived-red.svg)
![lifecycle](https://img.shields.io/badge/lifecycle-dormant-blue.svg) -->
[![build](https://github.com/gkantsidis/SAIMOpt.jl/workflows/CI/badge.svg)](https://github.com/gkantsidis/SAIMOpt.jl/actions?query=workflow%3ACI)
<!-- travis-ci.com badge, uncomment or delete as needed, depending on whether you are using that service. -->
<!-- [![Build Status](https://travis-ci.com/gkantsidis/SAIMOpt.jl.svg?branch=master)](https://travis-ci.com/gkantsidis/SAIMOpt.jl) -->
<!-- Coverage badge on codecov.io, which is used by default. -->
[![codecov.io](http://codecov.io/github/gkantsidis/SAIMOpt.jl/coverage.svg?branch=master)](http://codecov.io/github/gkantsidis/SAIMOpt.jl?branch=master)
<!-- Documentation -- uncomment or delete as needed -->
<!--
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://gkantsidis.github.io/SAIMOpt.jl/stable)
[![Documentation](https://img.shields.io/badge/docs-master-blue.svg)](https://gkantsidis.github.io/SAIMOpt.jl/dev)
-->
<!-- Aqua badge, see test/runtests.jl -->
<!-- [![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl) -->
