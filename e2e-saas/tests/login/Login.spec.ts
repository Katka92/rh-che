/*********************************************************************
 * Copyright (c) 2019 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 **********************************************************************/

 import { ICheLoginPage, TYPES, CLASSES, Dashboard } from 'e2e';
import { rhcheContainer } from '../../inversify.config';

 const loginPage: ICheLoginPage = rhcheContainer.get<ICheLoginPage>(TYPES.CheLogin);
 const dashboard: Dashboard = rhcheContainer.get(CLASSES.Dashboard);

suite('Login and wait dashboard', async () => {
    test('Login', async () => {
        console.log("Hello from downstream project!");
        await loginPage.login();
        await dashboard.waitPage(30000);
    });
});
