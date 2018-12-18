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

import com.redhat.che.selenium.core.workspace.RhCheWorkspaceTemplate;
import org.eclipse.che.selenium.core.workspace.InjectTestWorkspace;
import org.eclipse.che.selenium.core.workspace.TestWorkspace;
import org.testng.annotations.BeforeClass;

public class BayesianPackageJson extends BayesianAbstractTestClass {

  @InjectTestWorkspace(template = RhCheWorkspaceTemplate.RH_NODEJS)
  private TestWorkspace workspace;

  private static final Integer JSON_EXPECTED_ERROR_LINE = 12;
  private static final Integer JSON_INJECTION_ENTRY_POINT = 12;
  private static final String JSON_EXPECTED_ERROR_TEXT = "1.7.1";
  private static final String PROJECT_FILE = "package.json";
  private static final String PATH_TO_FILE = "nodejs-hello-world";
  private static final String PROJECT_NAME = "nodejs-hello-world";
  private static final String PROJECT_DEPENDENCY = "\"serve-static\": \"1.7.1\" ,\n";
  private static final String ERROR_MESSAGE =
      "Package serve-static-1.7.1 is vulnerable: CVE-2015-1164. Recommendation: use version 1.7.2";

  @BeforeClass
  public void setUp() throws Exception {
    super.setPathToFile(PATH_TO_FILE);
    super.setExpectedErrorLine(JSON_EXPECTED_ERROR_LINE);
    super.setExpectedErrorText(JSON_EXPECTED_ERROR_TEXT);
    super.setInjectionEntryPoint(JSON_INJECTION_ENTRY_POINT);
    super.setProjectFile(PROJECT_FILE);
    super.setPathToFile(PATH_TO_FILE);
    super.setErrorMessage(ERROR_MESSAGE);
    super.setProjectName(PROJECT_NAME);
    super.setProjectDependency(PROJECT_DEPENDENCY);
    super.setWorksapce(workspace);
    super.openTestFile();
  }
}
