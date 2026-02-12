// app/api/users/[id]/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;

    // Get parent with all relations
    const parent = await prisma.parent.findUnique({
      where: { parent_id: params.id },
      include: {
        users: true, // ถ้ามี users table
        parent_and_child: {
          include: {
            child: {
              select: {
                child_id: true,
                name_surname: true,
                birthday: true,
                wallet: true,
                update_wallet: true
              }
            }
          }
        },
        activity_record: {
          take: 10,
          orderBy: { created_at: 'desc' },
          include: {
            child: {
              select: {
                name_surname: true
              }
            },
            activity: {
              select: {
                name_activity: true,
                category: true
              }
            }
          }
        },
        parent_and_medals: {
          include: {
            medals: {
              select: {
                id: true,
                name_medals: true,
                point_medals: true
              }
            }
          }
        },
        redemption: {
          take: 10,
          orderBy: { created_at: 'desc' },
          include: {
            child: {
              select: {
                name_surname: true
              }
            },
            medals: {
              select: {
                name_medals: true
              }
            }
          }
        }
      }
    });

    if (!parent) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      );
    }

    // Transform children data
    const children = parent.parent_and_child.map((pc) => ({
      id: pc.child?.child_id || '',
      fullName: pc.child?.name_surname || 'N/A',
      dob: pc.child?.birthday?.toISOString(),
      score: pc.child?.wallet ? Number(pc.child.wallet) : 0,
      scoreUpdate: pc.child?.update_wallet ? Number(pc.child.update_wallet) : 0,
      relationship: pc.relationship || 'N/A'
    }));

    // Transform activity records
    const recentActivities = parent.activity_record.map((record) => ({
      id: record.ActivityRecord_id,
      activityName: record.activity?.name_activity || 'N/A',
      category: record.activity?.category || 'N/A',
      dateCompleted: record.date?.toISOString() || record.created_at.toISOString(),
      scoreEarned: record.point ? Number(record.point) : 0,
      status: 'Completed'
    }));

    // Transform rewards (medals)
    const rewards = parent.parent_and_medals.map((pm) => ({
      rewardId: pm.medals?.id || '',
      name: pm.medals?.name_medals || 'N/A',
      cost: pm.medals?.point_medals ? Number(pm.medals.point_medals) : 0
    }));

    // Transform redemptions
    const recentRedemptions = parent.redemption.map((redemption) => ({
      id: redemption.redemption_id,
      rewardName: redemption.medals?.name_medals || 'N/A',
      childName: redemption.child?.name_surname || 'N/A',
      dateRedeemed: redemption.date_redemption?.toISOString() || redemption.created_at.toISOString(),
      scoreUsed: redemption.point_for_reward ? Number(redemption.point_for_reward) : 0
    }));

    // Extract role from Supabase user metadata
    const meta = (parent.users?.raw_user_meta_data as Record<string, any>) || {};

    // Transform to match frontend interface
    const userDetail = {
      id: parent.parent_id,
      userId: parent.user_id,
      fullName: parent.name_surname || 'N/A',
      email: parent.email,
      role: meta.role || 'user',
      status: 'Active',
      verification: 'Verified',
      photoUrl: undefined,
      createdAt: parent.created_date.toISOString(),
      children,
      recentActivities,
      rewards,
      recentRedemptions
    };

    return NextResponse.json(userDetail);
  } catch (error: any) {
    const params = await context.params;
    console.error(`GET /api/users/${params.id} error:`, error);
    return NextResponse.json(
      { error: 'Failed to fetch user detail', details: error.message },
      { status: 500 }
    );
  }
}

export async function PATCH(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    const body = await request.json();
    const { role } = body;

    if (!role || !['user', 'admin'].includes(role)) {
      return NextResponse.json(
        { error: 'Invalid role. Must be "user" or "admin".' },
        { status: 400 }
      );
    }

    // Find parent to get user_id
    const parent = await prisma.parent.findUnique({
      where: { parent_id: params.id },
      select: { user_id: true, users: { select: { raw_user_meta_data: true } } }
    });

    if (!parent || !parent.user_id) {
      return NextResponse.json(
        { error: 'User not found or no linked auth user' },
        { status: 404 }
      );
    }

    // Merge new role into existing metadata
    const existingMeta = (parent.users?.raw_user_meta_data as Record<string, any>) || {};
    const updatedMeta = { ...existingMeta, role };

    // Update auth.users raw_user_meta_data
    await prisma.users.update({
      where: { id: parent.user_id },
      data: { raw_user_meta_data: updatedMeta }
    });

    return NextResponse.json({ success: true, role });
  } catch (error: any) {
    const params = await context.params;
    console.error(`PATCH /api/users/${params.id} error:`, error);
    return NextResponse.json(
      { error: 'Failed to update role', details: error.message },
      { status: 500 }
    );
  }
}