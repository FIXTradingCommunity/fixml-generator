package io.fixprotocol.orchestra.fixml;

import static org.junit.Assert.*;

import java.io.FileNotFoundException;

import javax.xml.transform.TransformerException;

import org.junit.Test;

public class FixmlGeneratorTest {

  @Test
  public void testMain() throws FileNotFoundException, TransformerException {
    String[] args = {"src/test/resources/FixRepository2016.xml", "target/test", "target/test/error.txt"};
    FixmlGenerator.main(args);
  }

}
