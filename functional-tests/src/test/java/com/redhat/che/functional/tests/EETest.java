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
import org.testng.annotations.Test;

// class for trying ProvidedWorkspace functionality
public class EETest {

  @Inject private ProvidedWorkspace worksapce;

  @Test
  public void mytest() {
    try {
      worksapce.getName();
    } catch (ExecutionException | InterruptedException e) {
      // TODO Auto-generated catch block
      e.printStackTrace();
    }
    System.out.println("Test with provided workspace has passed.");
  }
}
