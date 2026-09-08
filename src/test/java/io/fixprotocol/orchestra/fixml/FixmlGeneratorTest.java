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

import java.net.URI;
import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.core.appender.ConsoleAppender;
import org.apache.logging.log4j.core.config.Configurator;
import org.apache.logging.log4j.core.config.builder.api.AppenderComponentBuilder;
import org.apache.logging.log4j.core.config.builder.api.ConfigurationBuilder;
import org.apache.logging.log4j.core.config.builder.api.ConfigurationBuilderFactory;
import org.apache.logging.log4j.core.config.builder.impl.BuiltConfiguration;
import org.apache.logging.log4j.spi.LoggerContextFactory;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

class CustomLogFactory implements LoggerContextFactory {
  private final org.apache.logging.log4j.spi.LoggerContext ctx;

  CustomLogFactory() {
    final ConfigurationBuilder<BuiltConfiguration> builder =
        ConfigurationBuilderFactory.newConfigurationBuilder();
    builder.setStatusLevel(Level.WARN);
    final AppenderComponentBuilder appenderBuilder = builder.newAppender("Stdout", "CONSOLE")
        .addAttribute("target", ConsoleAppender.Target.SYSTEM_OUT)
        .add(builder.newLayout("PatternLayout").addAttribute("pattern",
            "%date %-5level: %msg%n%throwable"));
    builder.add(appenderBuilder);
    builder.add(builder.newRootLogger(Level.INFO).add(builder.newAppenderRef("Stdout")));
    ctx = Configurator.initialize(builder.build());
  }

  @Override
  public org.apache.logging.log4j.spi.LoggerContext getContext(String fqcn, ClassLoader loader,
      Object externalContext, boolean currentContext) {
    return ctx;
  }

  @Override
  public org.apache.logging.log4j.spi.LoggerContext getContext(String fqcn, ClassLoader loader,
      Object externalContext, boolean currentContext, URI configLocation, String name) {
    return ctx;
  }

  @Override
  public void removeContext(org.apache.logging.log4j.spi.LoggerContext context) {

  }
}

public class FixmlGeneratorTest {
  
  @BeforeAll
  static void setupOnce() {
    LogManager.setFactory(new CustomLogFactory());
  }

  @Test
  public void testMain() throws Exception {
    String[] args = {"src/test/resources/FixRepository2016.xml", "target/test"};
    FixmlGenerator.main(args);
  }

}
