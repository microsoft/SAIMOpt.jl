# `SAIMOpt.jl`

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

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.