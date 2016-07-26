/*******************************************************************************
 * Copyright (c) 2015 Dell Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Daniel Ford, Dell Corporation - initial API and implementation
 *     Urs Zeidler
 *******************************************************************************/
package com.dell.research.bc.eth.solidity.editor.tests

import com.dell.research.bc.eth.solidity.editor.SolidityInjectorProvider
import com.dell.research.bc.eth.solidity.editor.solidity.Solidity
import com.google.inject.Inject
import org.eclipse.xtext.junit4.InjectWith
import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.util.ParseHelper
import org.eclipse.xtext.junit4.validation.ValidationTestHelper
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(typeof(XtextRunner))
@InjectWith(typeof(SolidityInjectorProvider))
class DeleteStatementTest {
    @Inject extension ParseHelper<Solidity>;
    @Inject extension ValidationTestHelper

    val VALID_DELETE_STATEMENT = '''
       contract foo {
                    function bar() {delete i;}
                    }
    '''

    @Test
    def void givenValidExpression_thenNoErrors() {
        VALID_DELETE_STATEMENT.parse.assertNoErrors
    }

    val VALID_DELETE_ARRAY_STATEMENT = '''
       contract foo {
                    function bar() {delete i[1];}
                    }
    '''

    @Test
    def void givenValidDeleteArrayExpression_thenNoErrors() {
        VALID_DELETE_ARRAY_STATEMENT.parse.assertNoErrors
    }

    val VALID_DELETE_ARRAY_DIM_STATEMENT = '''
       contract foo {
                    function bar() {delete i[1][2];}
                    }
    '''

    @Test
    def void givenValidDeleteArrayDimExpression_thenNoErrors() {
        VALID_DELETE_ARRAY_DIM_STATEMENT.parse.assertNoErrors
    }

    val VALID_DELETE_QUALLIFIED_ARRAY_STATEMENT = '''
       contract foo {
                    function bar() {delete a.i[1];}
                    }
    '''

    @Test
    def void givenValidDeleteQualifiedArrayExpression_thenNoErrors() {
        VALID_DELETE_QUALLIFIED_ARRAY_STATEMENT.parse.assertNoErrors
    }
    
    val VALID_DELETE_QUALLIFIED_STATEMENT = '''
       contract foo {
                    function bar() {delete a.i;}
                    }
    '''

    @Test
    def void givenValidDeleteQualifiedExpression_thenNoErrors() {
        VALID_DELETE_QUALLIFIED_STATEMENT.parse.assertNoErrors
    }

} // DeleteStatementTest

