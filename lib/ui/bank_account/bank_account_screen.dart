import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/data/web_client.dart';
import 'package:invoiceninja_flutter/redux/app/app_actions.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/bank_account/bank_account_actions.dart';
import 'package:invoiceninja_flutter/redux/settings/settings_actions.dart';
import 'package:invoiceninja_flutter/ui/app/app_bottom_bar.dart';
import 'package:invoiceninja_flutter/ui/app/buttons/elevated_button.dart';
import 'package:invoiceninja_flutter/ui/app/help_text.dart';
import 'package:invoiceninja_flutter/ui/app/list_scaffold.dart';
import 'package:invoiceninja_flutter/ui/app/list_filter.dart';
import 'package:invoiceninja_flutter/ui/bank_account/bank_account_list_vm.dart';
import 'package:invoiceninja_flutter/ui/bank_account/bank_account_presenter.dart';
import 'package:invoiceninja_flutter/utils/dialogs.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bank_account_screen_vm.dart';

class BankAccountScreen extends StatelessWidget {
  const BankAccountScreen({
    Key key,
    @required this.viewModel,
  }) : super(key: key);

  static const String route = '/$kSettings/$kSettingsBankAccounts';

  final BankAccountScreenVM viewModel;

  void connectAccounts(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final webClient = WebClient();
    final credentials = state.credentials;
    final url = '${credentials.url}/one_time_token';

    store.dispatch(StartSaving());

    webClient
        .post(url, credentials.token,
            data: jsonEncode({
              'context': {'return_url': ''}
            }))
        .then((dynamic response) {
      store.dispatch(StopSaving());
      launchUrl(Uri.parse(
          '${cleanApiUrl(credentials.url)}/yodlee/onboard/${response['hash']}'));
    }).catchError((dynamic error) {
      store.dispatch(StopSaving());
      showErrorDialog(message: '$error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final userCompany = state.userCompany;
    final localization = AppLocalization.of(context);

    return ListScaffold(
      entityType: EntityType.bankAccount,
      onHamburgerLongPress: () => store.dispatch(StartBankAccountMultiselect()),
      appBarTitle: ListFilter(
        key: ValueKey(
            '__filter_${state.bankAccountListState.filterClearedAt}__'),
        entityType: EntityType.bankAccount,
        entityIds: viewModel.bankAccountList,
        filter: state.bankAccountListState.filter,
        onFilterChanged: (value) {
          store.dispatch(FilterBankAccounts(value));
        },
        onSelectedState: (EntityState state, value) {
          store.dispatch(FilterBankAccountsByState(state));
        },
      ),
      onCheckboxPressed: () {
        if (store.state.bankAccountListState.isInMultiselect()) {
          store.dispatch(ClearBankAccountMultiselect());
        } else {
          store.dispatch(StartBankAccountMultiselect());
        }
      },
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 16, top: 8, right: 16, bottom: 10),
            child: Row(
              children: [
                if (state.isHosted) ...[
                  if (state.isEnterprisePlan) ...[
                    Expanded(
                      child: AppButton(
                        label: localization.connect.toUpperCase(),
                        onPressed: () => connectAccounts(context),
                        iconData: Icons.link,
                      ),
                    ),
                    SizedBox(width: kGutterWidth),
                    Expanded(
                      child: AppButton(
                        label: localization.refresh.toUpperCase(),
                        onPressed: () => viewModel.onRefreshAccounts(context),
                        iconData: Icons.refresh,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 8),
                        child: Center(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HelpText(localization.upgradeToConnectBankAccount),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      launchUrl(Uri.parse(kBankingURL)),
                                  child: Text(localization.learnMore),
                                ),
                                TextButton(
                                  onPressed: () {
                                    store.dispatch(ViewSettings(
                                        clearFilter: true,
                                        company: state.company,
                                        user: state.user,
                                        section: kSettingsAccountManagement));
                                  },
                                  child: Text(localization.upgrade),
                                ),
                              ],
                            )
                          ],
                        )),
                      ),
                    ),
                  SizedBox(width: kGutterWidth),
                ],
                Expanded(
                  child: AppButton(
                    label: (state.isHosted
                            ? localization.rules
                            : localization.manageRules)
                        .toUpperCase(),
                    onPressed: () {
                      store.dispatch(
                          ViewSettings(section: kSettingsTransactionRules));
                    },
                    iconData: Icons.rule_folder,
                  ),
                )
              ],
            ),
          ),
          Expanded(child: BankAccountListBuilder()),
        ],
      ),
      bottomNavigationBar: AppBottomBar(
        entityType: EntityType.bankAccount,
        tableColumns: BankAccountPresenter.getAllTableFields(userCompany),
        defaultTableColumns:
            BankAccountPresenter.getDefaultTableFields(userCompany),
        onSelectedSortField: (value) {
          store.dispatch(SortBankAccounts(value));
        },
        sortFields: [
          BankAccountFields.name,
          BankAccountFields.type,
          BankAccountFields.balance,
        ],
        onSelectedState: (EntityState state, value) {
          store.dispatch(FilterBankAccountsByState(state));
        },
        onCheckboxPressed: () {
          if (store.state.bankAccountListState.isInMultiselect()) {
            store.dispatch(ClearBankAccountMultiselect());
          } else {
            store.dispatch(StartBankAccountMultiselect());
          }
        },
        onSelectedCustom1: (value) =>
            store.dispatch(FilterBankAccountsByCustom1(value)),
        onSelectedCustom2: (value) =>
            store.dispatch(FilterBankAccountsByCustom2(value)),
        onSelectedCustom3: (value) =>
            store.dispatch(FilterBankAccountsByCustom3(value)),
        onSelectedCustom4: (value) =>
            store.dispatch(FilterBankAccountsByCustom4(value)),
      ),
      floatingActionButton: state.prefState.isMenuFloated
          ? FloatingActionButton(
              heroTag: 'bank_account_fab',
              backgroundColor: Theme.of(context).primaryColorDark,
              onPressed: () => createEntityByType(
                  context: context, entityType: EntityType.bankAccount),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
              tooltip: localization.newBankAccount,
            )
          : null,
    );
  }
}
