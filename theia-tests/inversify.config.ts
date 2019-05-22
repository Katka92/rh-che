import { ILoginPage } from 'e2e';
import { TYPES, CLASSES } from 'e2e';
import { RhCheLoginPage } from './pageobjects/RhCheLoginPage';
import { e2eContainer } from 'e2e';
import { TestWorkspaceUtils } from './utils/TestWorkspaceUtils';

e2eContainer.unbind(TYPES.LoginPage);
e2eContainer.bind<ILoginPage>(TYPES.LoginPage).to(RhCheLoginPage).inSingletonScope();

e2eContainer.unbind(CLASSES.TestWorkspaceUtil);

e2eContainer.bind<TestWorkspaceUtils>(CLASSES.TestWorkspaceUtil).to(TestWorkspaceUtils).inSingletonScope();
const rhCheContainer = e2eContainer;

export { rhCheContainer };
