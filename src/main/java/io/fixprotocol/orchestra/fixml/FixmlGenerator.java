/*
 * Copyright 2019-2026 FIX Protocol Limited
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.fixprotocol.orchestra.fixml;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.StringWriter;
import javax.xml.transform.ErrorListener;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import net.sf.saxon.TransformerFactoryImpl;


/**
 * Generates FIXML schemas from an Orchestra file
 * 
 * @author Don Mendelson
 *
 */
public class FixmlGenerator {

  static final Logger parentLogger = LogManager.getLogger();


  /**
   * Generates FIXML schemas from an Orchestra file
   * 
   * @param args command line arguments.
   *        <ol>
   *        <li>The name of an Orchestra file (required)</li>
   *        <li>The path for output (required)</li>
   *        </ol>
   * @throws FileNotFoundException if the input file is not found
   * @throws TransformerException if an unrecoverable transformation error occurs
   */
  public static void main(String[] args) throws Exception {
    if (args.length < 2) {
      usage();
      System.exit(1);
    }
    File outdir = new File(args[1]);
    outdir.mkdirs();
    String outPath = outdir.getAbsolutePath();

    try (final InputStream inputXml = new FileInputStream(args[0])) {
      final Source xmlSource = new StreamSource(inputXml);
      final StringWriter sw = new StringWriter();
      final Result result = new StreamResult(sw);

      final TransformerFactory transFact = new TransformerFactoryImpl();
      final ClassLoader classLoader = FixmlGenerator.class.getClassLoader();
      final InputStream xsltStream =
          classLoader.getResourceAsStream("xsl/FIXMLSchemaGenerator.xsl");
      final Source xsltSource = new StreamSource(xsltStream);
      final Transformer trans = transFact.newTransformer(xsltSource);
      trans.setParameter("targetDir", outPath);
      trans.setErrorListener(new ErrorListener() {

        public void error(TransformerException exception) throws TransformerException {
          parentLogger.error(exception.getMessageAndLocation());
        }

        public void fatalError(TransformerException exception) throws TransformerException {
          parentLogger.fatal(exception.getMessageAndLocation());
        }

        public void warning(TransformerException exception) throws TransformerException {
          parentLogger.warn(exception.getMessageAndLocation());
        }

      });
      trans.transform(xmlSource, result);
      parentLogger.info("FixmlGenerator complete");
    } catch (Exception e) {
      parentLogger.fatal("FiximateGenerator failed", e);
      throw e;
    }
  }

  public static void usage() {
    System.err.println(
        "Usage: java io.fixprotocol.orchestra.fixml.FixmlGenerator <orchestra-file> <output-dir>");
  }

}
