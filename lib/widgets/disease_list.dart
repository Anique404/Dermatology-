import 'package:flutter/material.dart';
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.secondaryBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  const Text(
                    'Common Skin Diseases',
                    style: AppTextStyles.headline2,
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, color: AppColors.textLight),
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
                      color: AppColors.darkBg,
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.normal,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.normal,
                        ),
                        onTap: () => onDiseaseSelected(disease),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.normal),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.normal,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.small,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.health_and_safety,
                                  color: AppColors.accentTeal,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.normal),
                              Expanded(
                                child: Text(
                                  disease,
                                  style: AppTextStyles.subtitle1,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.accentTeal,
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
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.normal),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
