/*
 * Copyright 2018 FIX Protocol Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 *
 */

package io.fixprotocol.orchestra.fixml;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.PrintStream;
import java.io.StringWriter;

import javax.xml.transform.ErrorListener;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;

import net.sf.saxon.TransformerFactoryImpl;


/**
 * Generates FIXML schemas from an Orchestra file
 * 
 * @author Don Mendelson
 *
 */
public class FixmlGenerator {

  /**
   * Generates FIXML schemas from an Orchestra file
   * 
   * @param args command line arguments.
   *        <ol>
   *        <li>The name of an Orchestra file (required)</li>
   *        <li>The path for output (required)</li>
   *        <li>An error file -- defaults to err console</li>
   *        </ol>
   * @throws FileNotFoundException if the input file is not found
   * @throws TransformerException if an unrecoverable transformation error occurs
   */
  public static void main(String[] args) throws FileNotFoundException, TransformerException {
    if (args.length < 2) {
      usage();
      System.exit(1);
    }
    File outdir = new File(args[1]);
    outdir.mkdirs();
    String outPath = outdir.getAbsolutePath();

    final PrintStream errorStream;
    if (args.length > 2) {
      File errorFile = new File(args[2]);
      errorFile.getParentFile().mkdirs();
      errorStream = new PrintStream(new FileOutputStream(errorFile));
    } else {
      errorStream = System.err;
    }

    InputStream inputXml = new FileInputStream(args[0]);
    Source xmlSource = new StreamSource(inputXml);
    StringWriter sw = new StringWriter();
    Result result = new StreamResult(sw);

    TransformerFactory transFact = new TransformerFactoryImpl();
    ClassLoader classLoader = FixmlGenerator.class.getClassLoader();
    InputStream xsltStream = classLoader.getResourceAsStream("xsl/FIXMLSchemaGenerator.xsl");
    Source xsltSource = new StreamSource(xsltStream);
    Transformer trans = transFact.newTransformer(xsltSource);
    trans.setParameter("targetDir", outPath);
    trans.setErrorListener(new ErrorListener() {

      public void warning(TransformerException exception) throws TransformerException {
        errorStream.println(String.format("WARN:  %s", exception.getMessageAndLocation()));
      }

      public void error(TransformerException exception) throws TransformerException {
        errorStream.println(String.format("ERROR: %s", exception.getMessageAndLocation()));
      }

      public void fatalError(TransformerException exception) throws TransformerException {
        errorStream.println(String.format("FATAL: %s", exception.getMessageAndLocation()));
      }

    });
    trans.transform(xmlSource, result);
  }

  public static void usage() {
    System.err.println(
        "Usage: java io.fixprotocol.orchestra.fixml.FixmlGenerator <orchestra-file> <output-dir> [error-file]");
  }

}
