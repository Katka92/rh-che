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
import com.redhat.che.selenium.core.workspace.ProvidedWorkspace;
import java.util.concurrent.ExecutionException;
import org.eclipse.che.selenium.core.constant.TestGitConstants;
import org.eclipse.che.selenium.core.constant.TestMenuCommandsConstants;
import org.eclipse.che.selenium.pageobject.CodenvyEditor;
import org.eclipse.che.selenium.pageobject.Ide;
import org.eclipse.che.selenium.pageobject.Loader;
import org.eclipse.che.selenium.pageobject.Menu;
import org.eclipse.che.selenium.pageobject.NavigateToFile;
import org.eclipse.che.selenium.pageobject.git.Git;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;

// class for trying ProvidedWorkspace functionality
public class EETest {

  @Inject private ProvidedWorkspace workspace;
  @Inject private NavigateToFile navigateToFile;
  @Inject private Loader loader;
  @Inject private CodenvyEditor editor;
  @Inject private Ide ide;
  @Inject private Git git;
  @Inject private Menu menu;

  private String text = "protected static final String template = \"Bonjour, %s!\";";
  private String fileName = "HttpApplication", extension = ".java";
  private static final Logger LOG = LoggerFactory.getLogger(TestTestClass.class);

  @BeforeClass
  public void checkWorkspace() {
    try {
      LOG.info(
          "Workspace with name: "
              + workspace.getName()
              + " and id: "
              + workspace.getId()
              + " was successfully injected. ");
      ide.open(workspace);
      ide.waitOpenedWorkspaceIsReadyToUse();

    } catch (ExecutionException | InterruptedException e) {
      LOG.error(
          "Could not obtain workspace name and id - worskape was probably not successfully injected.");
      e.printStackTrace();
    } catch (Exception e) {
      LOG.error("Could not open workspace IDE.");
      e.printStackTrace();
    }
  }

  @Test(priority = 1)
  public void openClass() throws Exception {
    navigateToFile.launchNavigateToFileByKeyboard();
    navigateToFile.waitFormToOpen();
    loader.waitOnClosed();
    navigateToFile.typeSymbolInFileNameField(fileName);
    navigateToFile.selectFileByName(fileName + extension);
    loader.waitOnClosed();
    editor.waitActive();
  }

  @Test(priority = 2)
  public void changeLineText() {
    editor.selectLineAndDelete(14);
    editor.typeTextIntoEditor(text);
    editor.waitTabFileWithSavedStatus(fileName);
    editor.closeAllTabs();
  }

  @Test(priority = 3)
  public void gitCommit() {
    // Add file to index
    menu.runCommand(TestMenuCommandsConstants.Git.GIT, TestMenuCommandsConstants.Git.ADD_TO_INDEX);
    git.waitGitStatusBarWithMess(TestGitConstants.GIT_ADD_TO_INDEX_SUCCESS);

    // Check status
    menu.runCommand(TestMenuCommandsConstants.Git.GIT, TestMenuCommandsConstants.Git.STATUS);
    loader.waitOnClosed();
    String STATUS_MESSAGE_ONE_FILE =
        " On branch master\n"
            + " Changes to be committed:\n"
            + "  modified:   src/main/java/io/openshift/booster/HttpApplication.java";
    git.waitGitStatusBarWithMess(STATUS_MESSAGE_ONE_FILE);

    menu.runCommand(TestMenuCommandsConstants.Git.GIT, TestMenuCommandsConstants.Git.COMMIT);
    git.waitAndRunCommit("commits from test");
    git.waitGitStatusBarWithMess(TestGitConstants.COMMIT_MESSAGE_SUCCESS);

    git.pushChanges(false);
    git.waitPushFormToClose();
    git.waitGitStatusBarWithMess("Successfully pushed");
  }
}
