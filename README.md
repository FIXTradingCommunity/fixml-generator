# fixml-generator

Generates FIXML schemas from an Orchestra file.

## XSL Transform

### Script
`src/main/resources/xsl/FIXMLSchemaGenerator.xsl`

### Input

An Orchestra file that conforms to the XML schema of Orchestra version 1.0.
See http://fixprotocol.io/2020/orchestra/repository for the schema.

#### Parameter
`targetDir` give a path to write output files

### Output
A FIXML schema for each specified category of messages

### Prerequisite

Any standards-compliant XSLT 2.0 processor. The test wrapper uses Saxon-HE.

## Build

A Maven/Java wrapper is provided to invoke and test the script. This is not a run-time requirement.

## License
Copyright 2019-2026 FIX Protocol Limited

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
