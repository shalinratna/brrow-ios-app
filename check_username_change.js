const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkUsernameChange() {
  try {
    // Find Angel's user
    console.log('Finding Angel user...\n');
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { username: { contains: 'xiong', mode: 'insensitive' } },
          { username: { contains: 'angel', mode: 'insensitive' } }
        ]
      },
      select: {
        id: true,
        username: true,
        lastUsernameChange: true,
        usernameHistory: {
          orderBy: { changedAt: 'desc' },
          take: 10
        }
      }
    });

    if (user) {
      console.log('Current Username: ' + user.username);
      console.log('Last Change: ' + user.lastUsernameChange);
      console.log('\nUsername History:');
      user.usernameHistory.forEach((h, i) => {
        console.log('[' + (i+1) + '] ' + h.oldUsername + ' -> ' + h.newUsername);
        console.log('    Changed at: ' + h.changedAt);
        console.log('    Reserved until: ' + h.reservedUntil);
      });
    } else {
      console.log('User not found');
    }

    // Check if "angelk" is taken
    console.log('\nChecking if "angelk" is available...');
    const angelkUser = await prisma.user.findFirst({
      where: { username: 'angelk' }
    });
    
    if (angelkUser) {
      console.log('Username "angelk" is TAKEN by user ID: ' + angelkUser.id);
    } else {
      console.log('Username "angelk" is AVAILABLE');
    }

    // Check username history for "angelk"
    const angelkHistory = await prisma.usernameHistory.findFirst({
      where: { newUsername: 'angelk' },
      orderBy: { changedAt: 'desc' }
    });

    if (angelkHistory) {
      console.log('\nFound "angelk" in username history:');
      console.log('  Changed from: ' + angelkHistory.oldUsername);
      console.log('  Changed at: ' + angelkHistory.changedAt);
      console.log('  Reserved until: ' + angelkHistory.reservedUntil);
    }

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

checkUsernameChange();
