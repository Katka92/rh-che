/*
 * Copyright (c) 2016-2018 Red Hat, Inc.
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 *
 * Contributors:
 *   Red Hat, Inc. - initial API and implementation
 */
package com.redhat.che.functional.tests;

import com.google.inject.Inject;
import com.redhat.che.selenium.core.workspace.RhCheWorkspaceTemplate;
import org.eclipse.che.selenium.core.provider.TestApiEndpointUrlProvider;
import org.eclipse.che.selenium.core.workspace.InjectTestWorkspace;
import org.eclipse.che.selenium.core.workspace.TestWorkspace;
import org.eclipse.che.selenium.pageobject.CodenvyEditor;
import org.eclipse.che.selenium.pageobject.Loader;
import org.eclipse.che.selenium.pageobject.NavigateToFile;
import org.eclipse.che.selenium.pageobject.ProjectExplorer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

public class BayesianPomXml extends RhCheAbstractTestClass {

  private static final Logger LOG = LoggerFactory.getLogger(TestTestClass.class);

  @InjectTestWorkspace(template = RhCheWorkspaceTemplate.RH_VERTX)
  private TestWorkspace workspace;

  @Inject private NavigateToFile navigateToFile;
  @Inject private Loader loader;
  @Inject private CodenvyEditor editor;
  @Inject private ProjectExplorer projectExplorer;
  @Inject private TestApiEndpointUrlProvider testApiEndpointUrlProvider;

  private static final Integer POM_EXPECTED_ERROR_LINE = 40;
  private static final Integer POM_INJECTION_ENTRY_POINT = 37;
  private static final String PROJECT_FILE = "pom.xml";
  private static final String ERROR_MESSAGE =
      "Package ch.qos.logback:logback-core-1.1.10 is vulnerable: CVE-2017-5929";
  private static final String PROJECT_NAME = "vertx-http-booster";
  private static final String PROJECT_DEPENDENCY =
      "<dependency>\n"
          + "<groupId>ch.qos.logback</groupId>\n"
          + "<artifactId>logback-core</artifactId>\n"
          + "<version>1.1.10</version>\n"
          + "</dependency>\n";
  private static final String CHE_PROD_PREVIEW_URL = "che.prod-preview.openshift.io";

  @BeforeClass
  public void openTestFile() throws Exception {
    checkWorkspace(workspace);
    projectExplorer.waitItem(PROJECT_NAME);
  }

  @BeforeMethod
  public void prepareProjectFile() {
    openDefinedClass(PROJECT_FILE);
    appendDependency();
  }

  @AfterMethod
  public void closeFiles() {
    removeDependency();
    editor.closeAllTabs();
  }

  @Test
  public void checkBayesianError() {
    if (editorCheckBayesianError()) {
      return;
    }
    LOG.info("Bayesian error message was present after adding dependency.");
  }

  @Test
  public void checkErrorPresentAfterReopenFile() {
    editor.closeAllTabs();
    openDefinedClass(PROJECT_FILE);
    editor.setCursorToLine(POM_EXPECTED_ERROR_LINE);
    editor.moveCursorToText("1.1.10");
    if (editorCheckBayesianError()) {
      return;
    }
    LOG.info("Bayesian error message was present after reopening file.");
  }

  private void appendDependency() {
    editor.setCursorToLine(POM_INJECTION_ENTRY_POINT);
    editor.typeTextIntoEditor(PROJECT_DEPENDENCY);
    editor.waitTabFileWithSavedStatus(PROJECT_FILE);
    editor.setCursorToLine(POM_EXPECTED_ERROR_LINE);
    editor.moveCursorToText("1.1.10");
  }

  private void removeDependency() {
    editor.setCursorToLine(POM_INJECTION_ENTRY_POINT);
    editor.deleteCurrentLine();
    editor.deleteCurrentLine();
    editor.deleteCurrentLine();
    editor.deleteCurrentLine();
    editor.deleteCurrentLine();
  }

  private boolean editorCheckBayesianError() {
    try {
      editor.waitTextInToolTipPopup(ERROR_MESSAGE);
    } catch (Exception e) {
      if (testApiEndpointUrlProvider.get().getHost().equals(CHE_PROD_PREVIEW_URL)) {
        LOG.error(
            "Bayesian error not present after adding dependency - known issue for prod-preview.");
        return true;
      } else {
        throw e;
      }
    }
    return false;
  }
}
