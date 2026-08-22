import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';
import '../utils/constants.dart';

// ============================================
// DISEASE LIST WIDGET
// ============================================
class DiseaseListWidget extends StatelessWidget {
  final Function(String) onDiseaseSelected;
  final VoidCallback onClose;

  const DiseaseListWidget({
    Key? key,
    required this.onDiseaseSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                AppSpacing.large,
                AppSpacing.large,
                AppSpacing.normal,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Common Skin Diseases',
                    style: AppTextStyles.headline2,
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                ),
                itemCount: DiseaseList.diseases.length,
                itemBuilder: (context, index) {
                  final disease = DiseaseList.diseases[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.small),
                    child: Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.medium,
                        ),
                        onTap: () => onDiseaseSelected(disease),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.normal),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.medium,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.small,
                                  ),
                                ),
                                child: Icon(
                                  Icons.spa_outlined,
                                  color: AppColors.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.normal),
                              Expanded(
                                child: Text(
                                  disease,
                                  style: AppTextStyles.subtitle1,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.medium,
                      ),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
