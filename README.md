# Build AWS-iGenomes

[![MIT License][license-badge]][license-link]
[![Install with bioconda][bioconda-badge]][bioconda-link]
[![Docker Container available][docker-badge]][docker-link]

## Common reference genomes hosted on AWS S3

Building script for AWS-iGenomes

#### Download script & command builder: [https://ewels.github.io/AWS-iGenomes/](https://ewels.github.io/AWS-iGenomes/)

![Amazon Web Services](docs/images/AWS_logo.png)

## Introduction
In NGS bioinformatics, a typical analysis run involves aligning raw DNA sequencing reads against a known reference genome.
A different reference is needed for every species, and many species have several references to choose from.
Each tool then builds its own indices against these references.
As such, one analysis run typically requires a number of different files.
For example: raw underlying DNA sequence, annotation (GTF files) and index file for use the chosen alignment tool.

These files are quite large and take time to generate.
Downloading and building them for each AWS run often takes a significant of the total run time and resources, which is very wasteful.
The iGeomes initiative aims to collect and standardise a number of common species, references and tool indices.
To help with this, we have created an AWS S3 bucket containing the [illumina iGenomes](https://support.illumina.com/sequencing/sequencing_software/igenome.html) references, with a few additional indices for a extra tools on top of this base dataset.

This data is hosted in an S3 bucket (~5TB) and crucially is uncompressed (unlike the `.tar.gz` files held on the illumina iGenomes FTP servers).
AWS runs can by pull just the required files to their local file storage before running.
This has the advantage of being faster, cheaper and more reproducible.

## Credits
The [iGenomes](https://support.illumina.com/sequencing/sequencing_software/igenome.html) resource was created by illumina.
All credit for the collection and standardisation of this data should go to them!

This S3 resource was set up and documented by Phil Ewels ([@ewels](https://github.com/ewels)).
The additional references not found in the base iGenomes resource were created with the help of Wesley Schaal ([@wschaal](https://github.com/wschaal)) - a system administrator at [UPPMAX](https://www.uppmax.uu.se/) (Uppsala Multidisciplinary Center for Advanced Computational Science).

The resource was initially developed for use at the [National Genomics Infrastructure](https://portal.scilifelab.se/genomics/) at [SciLifeLab](http://www.scilifelab.se/) in Stockholm, Sweden.

---
[![SciLifeLab](docs/images/SciLifeLab_logo.png)](http://www.scilifelab.se/)
[![National Genomics Infrastructure](docs/images/NGI_logo.png)](https://ngisweden.scilifelab.se/)
---

[bioconda-badge]:https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?logo=data:image/png;base64,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
[bioconda-link]:http://bioconda.github.io/
[docker-badge]: https://img.shields.io/docker/automated/maxulysse/awsigenomesbuild.svg?logo=docker
[docker-link]: https://hub.docker.com/r/maxulysse/awsigenomesbuild
[license-badge]: https://img.shields.io/github/license/MaxUlysse/AWS-iGenomes-build.svg
[license-link]: https://github.com/MaxUlysse/AWS-iGenomes-build/blob/master/LICENSE
