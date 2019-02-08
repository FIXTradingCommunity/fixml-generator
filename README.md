# fixml-generator

Generates FIXML schemas from an Orchestra file.

## XSL Transform

### Script
`src/main/resources/xsl/FIXMLSchemaGenerator.xsl`

### Input

An Orchestra file that conforms to the XML schema of Orchestra version 1.0 RC4. 
See GitHub project fix-orchestra module repository2016 for the schema.
#### Parameter
`targetDir` give a path to write output files

### Output
A FIXML schema for each specified category of messages

### Prerequisite

Any standards-compliant XSLT 2.0 processor. The test wrapper uses Saxon-HE.

## Build

A Maven/Java wrapper is provided to invoke and test the script. This is not a run-time requirement.

## Deployment

The ultimate build and deployment process has not yet been decided.