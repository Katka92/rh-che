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
package com.redhat.che.selenium.core;

import static com.google.common.base.Strings.isNullOrEmpty;
import static java.lang.String.format;

import com.google.inject.Injector;
import com.google.inject.Key;
import com.google.inject.MembersInjector;
import com.google.inject.Provider;
import com.google.inject.name.Names;
import com.redhat.che.selenium.core.workspace.RhCheTestWorkspaceImpl;
import com.redhat.che.selenium.core.workspace.RhCheTestWorkspaceProvider;
import java.lang.reflect.Field;
import org.eclipse.che.selenium.core.user.DefaultTestUser;
import org.eclipse.che.selenium.core.workspace.InjectTestWorkspace;

public class RhCheTestWorkspaceInjector<T> implements MembersInjector<T> {
  private final Field field;
  private final InjectTestWorkspace injectTestWorkspace;
  private final Provider<Injector> injectorProvider;

  public RhCheTestWorkspaceInjector(
      Field field, InjectTestWorkspace injectTestWorkspace, Provider<Injector> injectorProvider) {
    this.field = field;
    this.injectTestWorkspace = injectTestWorkspace;
    this.injectorProvider = injectorProvider;
  }

  @Override
  public void injectMembers(T instance) {
    Injector injector = injectorProvider.get();

    RhCheTestWorkspaceProvider testWorkspaceProvider =
        injector.getInstance(RhCheTestWorkspaceProvider.class);
    int workspaceDefaultMemoryGb =
        injector.getInstance(Key.get(int.class, Names.named("workspace.default_memory_gb")));

    try {
      DefaultTestUser testUser =
          isNullOrEmpty(injectTestWorkspace.user())
              ? injector.getInstance(DefaultTestUser.class)
              : findInjectedUser(instance, injectTestWorkspace.user());

      RhCheTestWorkspaceImpl testWorkspace =
          (RhCheTestWorkspaceImpl)
              testWorkspaceProvider.createWorkspace(
                  testUser, 0, null, injectTestWorkspace.startAfterCreation());
      testWorkspace.await();

      field.setAccessible(true);
      field.set(instance, testWorkspace);
    } catch (Exception e) {
      throw new RuntimeException(
          "Failed to instantiate workspace in " + instance.getClass().getName(), e);
    }
  }

  private DefaultTestUser findInjectedUser(T instance, String userEmail) {
    for (Field field : instance.getClass().getDeclaredFields()) {
      if (field.getType() == DefaultTestUser.class) {
        field.setAccessible(true);

        DefaultTestUser testUser;
        try {
          testUser = (DefaultTestUser) field.get(instance);
        } catch (IllegalAccessException e) {
          throw new IllegalArgumentException(e);
        }

        if (testUser != null && testUser.getEmail().equals(userEmail)) {
          return testUser;
        }
      }
    }

    throw new IllegalArgumentException(
        format(
            "User %s not found or isn't instantiated in %s",
            userEmail, instance.getClass().getName()));
  }
}
