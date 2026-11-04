import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../utils/app_constants.dart';
import 'status_badge.dart';

class IncidentCard extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppConstants.cardWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppConstants.borderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8.0,
            offset: Offset(0.0, 2.0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // 1. Left Thumbnail (Photo or Category Icon Fallback)
                _buildThumbnail(),
                const SizedBox(width: 12.0),

                // 2. Middle Details (Title, Location, Relative Time)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        incident.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textDark,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        incident.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13.0,
                            color: AppConstants.textSecondary,
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              incident.timeAgo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.0,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),

                // 3. Right Status Badge & Chevron Arrow
                StatusBadge(status: incident.status, isCompact: true),
                const SizedBox(width: 4.0),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppConstants.textSecondary,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (incident.hasPhoto && incident.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Image.network(
          incident.imageUrl!,
          width: 64.0,
          height: 64.0,
          fit: BoxFit.cover,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return _buildFallbackIcon();
          },
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 64.0,
      height: 64.0,
      decoration: BoxDecoration(
        color: AppConstants.lightBlueSurface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(
        AppConstants.getCategoryIcon(incident.category),
        color: AppConstants.primaryBlue,
        size: 28.0,
      ),
    );
  }
}